import java.io.*;
import java.util.*;
import org.apache.jena.rdf.model.*;
import org.apache.jena.query.*;
import org.apache.commons.lang3.StringEscapeUtils;
import org.apache.jena.update.*;


public class AG2dot {

	public static void main(String[] argv) throws Exception {
		if(argv.length==0 || Arrays.asList(argv).toString().contains("-?"))
			System.err.println("AG2dot [URL|File] [-?] [-keepIDs] [-skip prop1[..n]] [-anchors INT | -anchors all]\n"+
				"\tFile     RDF file\n"+
				"\tURL      URL of an RDF file\n"+
				"\t-?       this text\n"+
				"\t-keepIDs keep attributes with local name \"id\" (by default suppressed)\n"+
				"\t-skip    skip the following properties from the output\n"+
				"\t-anchors keep only the first INT anchors (default: 10)\n"+
				"\t     all keep all anchors"+
				"reads from file and writes Dot file *of the complete document* to stdout\n");
		
		boolean keepIDs = Arrays.asList(argv).toString().toLowerCase().contains("-keepids"); 
		String url = argv[0];
		Model model = ModelFactory.createDefaultModel();
		model.read(url);
		
		int anchorLimit = 10;
		if(Arrays.asList(argv).toString().toLowerCase().contains("-anchors, all")) {
			anchorLimit=-1;
		} else 
			for(int i = 1; i<argv.length; i++)
				if(argv[i-1].toLowerCase().equals("-anchors"))
					anchorLimit=Integer.parseInt(argv[i]);			
		
		// skip removable properties
		int arg = 0;
		HashSet<Statement> removables = new HashSet<Statement>();
		while(arg<argv.length && !argv[arg].toLowerCase().equals("-skip")) arg++;
		while(arg<argv.length) {
			String query = "SELECT ?a ?b WHERE { ?a <"+argv[arg]+"> ?b.}";
			ResultSet results = QueryExecutionFactory.create(QueryFactory.create(query),model).execSelect();
			while(results.hasNext()) {
				QuerySolution result = results.next();
				removables.add(
						ResourceFactory.createStatement(
								(Resource) result.get("a"),
								ResourceFactory.createProperty(argv[arg]), 
								result.get("b")));
			}
			arg++;
		}
		for(Statement removable : removables)
			model.remove(removable);
		
		if(anchorLimit>0) {
			// todo: keep only the first anchorLimit Anchors and their annotations
			// note: this may actually require some heavy transformation
			String update =
				"PREFIX ag: <http://www.ldc.upenn.edu/atlas/ag/>\n"+
				"PREFIX tmp: <http://example.org/tmp/>\n"+
				"\n"+
				"# mark the first anchor as tmp:Anchor\n"+
				"INSERT { ?a a tmp:Anchor }\n"+
				"WHERE {\n"+
				"	SELECT distinct ?a\n"+
				"	WHERE {\n"+
				"      ?a a ag:Anchor.\n"+
				"      FILTER(NOT EXISTS { [] ag:nextAnchor ?a } )\n"+
				"    } GROUP BY ?a LIMIT 1\n"+
				"  };\n";
			
			update=update+"\n"+
					"# mark following anchors as tmp:Anchor\n";
					
			for(int i = 0; i<anchorLimit; i++)
				update=update+
					"INSERT { ?b a tmp:Anchor }\n"+
					"WHERE {\n"+
					"  ?a a tmp:Anchor.\n"+
					"  ?a ag:nextAnchor ?b.\n"+
					"  FILTER(NOT EXISTS{ ?b a tmp:Anchor })\n"+
					"};\n";
	
			/* with explicit distances, rather slow
				"PREFIX ag: <http://www.ldc.upenn.edu/atlas/ag/>\n"+
				"PREFIX tmp: <http://example.org/tmp/>\n"+
				"\n"+
				"# mark the first 20 anchors as tmp:Anchor\n"+
				"INSERT { ?a a tmp:Anchor }\n"+
				"WHERE {\n"+
				"	SELECT distinct ?a (COUNT(DISTINCT ?tmp) AS ?distance)\n"+
				"	WHERE {\n"+
				"      ?firstAnchor a ag:Anchor.\n"+
				"      FILTER(NOT EXISTS { [] ag:nextAnchor ?firstAnchor } )\n"+
				"      ?firstAnchor ag:nextAnchor* ?a.\n"+
				"      OPTIONAL {\n"+
				"        ?firstAnchor ag:nextAnchor* ?tmp.\n"+
				"		?tmp ag:nextAnchor* ?a.\n"+
				"      }\n"+
				"    } GROUP BY ?firstAnchor ?a ORDER BY ?distance LIMIT 10\n"+
				"  };\n" */
			
			update=update+
					"\n"+
					"# create tmp:point_to relations between all Annotations that are connected to each other\n"+
					"INSERT { ?anno1 tmp:point_to ?anno2 }\n"+
					"WHERE {\n"+
					"	?anno1 a ag:Annotation.\n"+
					"	?anno1 ?rel ?anno2.\n"+
					"	?anno2 a ag:Annotation.\n"+
					"};\n"+
					"		\n"+
					"# mark annotations that point directly or indirectly to an tmp:Anchor as tmp:Annotation\n"+
					"INSERT { ?anno a tmp:Annotation }\n"+
					"WHERE {\n"+
					"	?anno a ag:Annotation.\n"+
					"	{ ?anno tmp:point_to*/(ag:end|ag:start)/a tmp:Anchor. } UNION \n"+
					"	{ ?anno (^tmp:point_to)*/(ag:end|ag:start)/a tmp:Anchor .}\n"+
					"};\n"+
					"\n"+
					"# delete all Annotations that are no tmp:Annotation\n"+
					"DELETE { ?a ?b ?anno. ?anno ?c ?d }\n"+
					"WHERE {\n"+
					"  ?anno a ag:Annotation.\n"+
					"  FILTER(NOT EXISTS { ?anno a tmp:Annotation })\n"+
					"  { ?a ?b ?anno } UNION { ?anno ?c ?d }\n"+
					"};\n"+
					"\n"+
					"# delete all Anchors that are no tmp:Anchor\n"+
					"DELETE { ?a ?b ?anchor. ?anchor ?c ?d }\n"+
					"WHERE {\n"+
					"  ?anchor a ag:Anchor.\n"+
					"  FILTER(NOT EXISTS { ?anchor a tmp:Anchor })\n"+
					"  { ?a ?b ?anchor } UNION { ?anchor ?c ?d }\n"+
					"};\n"+
					"\n"+
					"# delete tmp:Anchor\n"+
					"DELETE { ?a a tmp:Anchor }\n"+
					"WHERE { ?a a tmp:Anchor };\n"+
					"\n"+
					"# delete tmp:Annotation\n"+
					"DELETE { ?a a tmp:Annotation }\n"+
					"WHERE { ?a a tmp:Annotation };\n"+
					"\n"+
					"# delete tmp:point_to\n"+
					"DELETE { ?a tmp:point_to ?b }\n"+
					"WHERE { ?a tmp:point_to ?b }";
			
			UpdateAction.parseExecute( update, model );
		 }
		
		 System.out.println("digraph G {\n"
		 		+ "overlap=false;");
		 
		 // fetch all anchors
		 System.out.println("subgraph ag_Anchors {\n"
				+ "node [shape=plaintext];\n"
				+ "rank=same;");
		
		String query = 
				"PREFIX ag: <http://www.ldc.upenn.edu/atlas/ag/>\n"+
					"SELECT ?a ?anno ?next\n"+
					"WHERE {\n"+
					  "?a a ag:Anchor.\n"+
					  "OPTIONAL { ?a ag:nextAnchor ?next }\n"+
					  "{ SELECT ?a (group_concat(?val;separator='<BR/>') AS ?anno)\n"+
					    "WHERE {\n"+
					      "?a ?dprop ?literal.\n"+
					      "FILTER isLiteral(?literal)\n";
		if(!keepIDs) query = query + 
				          "FILTER (!regex(str(?dprop),'.*[#/]id$'))\n";
		query=query +     "BIND(concat(replace(str(?dprop),'.*[/#]',''),'=',?literal) AS ?val)\n"+
					    "} GROUP BY ?a ORDER BY ?a ?dprop ?literal\n"+
					  "}\n"+
					"}\n";
		
		try (QueryExecution qexec = QueryExecutionFactory.create(QueryFactory.create(query),model)) {
			ResultSet anchors = qexec.execSelect() ;
			while( anchors.hasNext() ) {
			  QuerySolution anchor = anchors.nextSolution();
			  System.out.println(escapeURI(anchor.get("a"))+" [label=<"+escapeAnno(anchor.get("anno"))+">];");
			  if(anchor.get("next")!=null) 
				  System.out.println(escapeURI(anchor.get("a"))+" -> "+escapeURI(anchor.get("next"))+" [color=none];");
			}
		}
				
		System.out.println("}");
		
		// retrieve Annotation types (=> one subgraph per type
		query = "PREFIX ag: <http://www.ldc.upenn.edu/atlas/ag/>\n"
				+ "SELECT DISTINCT ?t\n"
				+ "WHERE {\n"
				+ "?x a ag:Annotation.\n"
				+ "?x ag:type ?t\n"
				+ "}";
		ResultSet result = QueryExecutionFactory.create(QueryFactory.create(query), model).execSelect();
		ArrayList<String> types = new ArrayList<String>();
		while(result.hasNext())
			types.add(result.next().get("t").toString());
		
		for(int i = 0; i<types.size(); i++) {
			String type = types.get(i);
			System.out.println("subgraph "+/*"cluster_"+*/type.replaceAll("[^a-zA-Z0-9]+", "_")+" {\n"
					+ "node [shape=box];\n"
					+ "graph[style=dotted];");
				// System.out.println("splines=ortho");	// nicer edges (I presume)
		
				// write Annotation nodes
				query=	"PREFIX ag: <http://www.ldc.upenn.edu/atlas/ag/>\n"+
						"SELECT ?x ?anno\n"+
						"WHERE {\n"+
						  "?x a ag:Annotation.\n"+
						  "?x ag:type '"+type+"'.\n"+
						  "OPTIONAL { SELECT ?x (group_concat(?val;separator='<BR/>') as ?anno)\n"+
						    "WHERE {\n"+
						      "?x ?dprop ?literal.\n"+
						      "FILTER (isLiteral(?literal))\n"+
						      "FILTER (?dprop!=ag:type)\n"+
						      "BIND(concat(replace(str(?dprop),'.*[#/]',''),'<BR/>',?literal,'<BR/>') AS ?val)\n"+
						    "} GROUP BY ?x ORDER BY ?x ?dprop ?literal\n"+
							"}\n"+
						  "}\n";
				ResultSet annos = QueryExecutionFactory.create(QueryFactory.create(query), model).execSelect();
				while(annos.hasNext()) {
					QuerySolution anno= annos.next();
					System.out.println(escapeURI(anno.get("x"))+" [label=<"+type+"<BR/><BR/>"+escapeAnno(anno.get("anno"))+">];");
					}
				
				// write relations
				query=	"PREFIX ag: <http://www.ldc.upenn.edu/atlas/ag/>\n"+
						"PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n"+
						"SELECT ?x ?rel ?tgt\n"+
						"WHERE {\n"+
						  "?x a ag:Annotation.\n"+
						  "?x ag:type '"+type+"'.\n"+
						  "?x ?oprop ?tgt.\n"+
						  "FILTER(!isLiteral(?tgt))\n"+
						  "FILTER(?oprop!=rdf:type)\n"+
						  "BIND(replace(str(?oprop),'.*[#/]','') AS ?rel)\n"+
						"}";
				ResultSet rels = QueryExecutionFactory.create(QueryFactory.create(query), model).execSelect();
						
				while(rels.hasNext()) {
					QuerySolution rel= rels.next();
					System.out.print(escapeURI(rel.get("x"))+" -> "+escapeURI(rel.get("tgt"))+" [xlabel=\""+rel.get("rel")+"\"];\n");
				}
				
				System.out.println("}");
		}
		
		// draw invisible edges to rank subgraphs
		query="PREFIX ag: <http://www.ldc.upenn.edu/atlas/ag/>\n"
				+ "SELECT ?x ?y\n"
				+ "WHERE {\n"
				+ "  ?x a ag:Annotation.\n"
				+ "  { ?x ag:start/ag:nextAnchor*/^ag:start ?y.\n"
				+ "    ?x ag:end/(^ag:nextAnchor)*/^ag:end ?y.\n"
				+ "  } UNION {\n"
				+ "    ?x ?rel ?y. ?y a ag:Annotation.\n"
				+ "  }"
				+ "  FILTER (?x != ?y)\n"
				+ "}";
		
		ResultSet rels = QueryExecutionFactory.create(QueryFactory.create(query), model).execSelect();
		while(rels.hasNext()) {
			QuerySolution rel= rels.next();
			System.out.print(escapeURI(rel.get("x"))+" -> "+escapeURI(rel.get("y"))+" [style=invisible, arrowhead=none]"+";\n");
		}
		
		System.out.println("}");
	}

	private static String escapeAnno(RDFNode rdfNode) {
		if(rdfNode==null) return "";
		return StringEscapeUtils.escapeHtml4(rdfNode.toString())
				.replaceAll("&lt;","<")
				.replaceAll("&gt;",">")
				.replaceAll("&quot;","\"")
				.replaceAll("&amp;","&");
	}

	private static String escapeLabel(RDFNode rdfNode) {
		return StringEscapeUtils.escapeHtml4(rdfNode.toString());
		//.replaceAll("ö","oe").replaceAll("ß", "ss");
	}

	private static String escapeURI(RDFNode rdfNode) {
		return rdfNode.toString().replaceAll("[/:#\\.]", "");
	}
}

		
			
		