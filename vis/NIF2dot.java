import java.io.*;
import java.util.*;
import org.apache.jena.rdf.model.*;
import org.apache.jena.query.*;
import org.apache.commons.lang3.StringEscapeUtils;

public class NIF2dot {

	public static void main(String[] argv) throws Exception {
		if(argv.length==0 || Arrays.asList(argv).toString().contains("-?")) 
			System.err.println("NIF2dot [URL|File] [-?] [-keepIDs] [-skip prop1[..n]]\n"+
				"\tFile     RDF file\n"+
				"\tURL      URL of an RDF file\n"+
				"\t-?       this text\n"+
				"\t-keepIDs keep attributes with local name \"id\" (by default suppressed)\n"+
				"\t-skip    skip the following properties from the output\n"+
				"reads from file and writes Dot file *of the first sentence* to stdout");
		
		boolean keepIDs = Arrays.asList(argv).toString().toLowerCase().contains("-keepids"); 
		String url = argv[0];
		Model model = ModelFactory.createDefaultModel();
		model.read(url);
		
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
		
		// fetch first sentence
		String query = 
			"PREFIX nif: <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#>\n"+
			"SELECT ?initialSentence "
			+ "WHERE { ?initialSentence a nif:Sentence. "
					+ "FILTER(NOT EXISTS { [] nif:nextSentence ?initialSentence })"
			+ "} ORDER BY ?initialSentence LIMIT 1";
		  try (QueryExecution qexec = QueryExecutionFactory.create(QueryFactory.create(query),model)) {
			ResultSet initialSentences = qexec.execSelect() ;
			while( initialSentences.hasNext() ) {
			  Resource initialSentence = initialSentences.nextSolution().getResource("initialSentence");

			  System.out.println("digraph G {\n"
					+ "subgraph nif_Words {\n"
					+ "node [shape=plaintext];\n"
					+ "rank=same;");
			  
			  // fetch all Words of the current sentence and their annotations
			  query =
				"PREFIX nif: <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#>\n"+
				"PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n"+
				"SELECT ?word ?label ?anno ?nextWord\n"
				+ "WHERE { <"+initialSentence+"> nif:firstWord/nif:nextWord* ?word.\n"
						+ "OPTIONAL { ?word rdfs:label ?label. }\n"
						+ "OPTIONAL { ?word nif:nextWord ?nextWord. }\n"
						+ "{ SELECT ?word ( group_concat ( distinct ?val;separator=\"<BR/>\" ) as ?anno )\n"
						  + "WHERE { OPTIONAL { ?word rdfs:label ?string }\n"
						          + "?word ?rel ?obj.\n"
						          + "FILTER isLiteral(?obj)\n";
			  if(!keepIDs)
				  query = query   + "FILTER (!regex(str(?rel),'.*[#/]id$'))\n";
			  query=query         + "FILTER (?rel!=rdfs:label) \n"
						          //+ "BIND(concat(replace(str(?rel),'.*[#/]',''),'=',?obj) AS ?val)\n"
						          + "BIND(?obj AS ?val)\n"
						  + "} GROUP BY ?word ORDER BY ?word ?rel ?val\n"
					    + "}\n"
					    //+ "BIND(concat(?label,'<BR/>',?anno) AS ?node_label)\n"
						//+ "BIND(concat(?label,'<BR/><FONT POINT-SIZE=\\'8\\'>',?anno,'</FONT>') AS ?node_label)\n"
				+ "}";
			  ResultSet words = QueryExecutionFactory.create(QueryFactory.create(query), model).execSelect();
				
				while(words.hasNext()) {
					QuerySolution word = words.next();
					System.out.println(escapeURI(word.get("word"))+
							" [label=<"+escapeLabel(word.get("label"))+
							"<BR/><FONT POINT-SIZE=\"10\">"+escapeAnno(word.get("anno"))+"</FONT>>];");
					if(word.get("nextWord")!=null) System.out.println(escapeURI(word.get("word"))+" -> "+escapeURI(word.get("nextWord"))+" [color=none];");
				}
				
				System.out.println("}");
		
				System.out.println("subgraph nif_Phrases {\n"
						+ "node [shape=box];");
				// System.out.println("splines=ortho");	// nicer edges, but don't go together with edge labels
				
				// flatten reification
				RSIterator reifications = model.listReifiedStatements();
				while(reifications.hasNext()) {
					ReifiedStatement r = reifications.next();
					model.add(r.getStatement());
					//System.out.println(r.getStatement());
				}
				
				// write phrase nodes
				query=	"PREFIX nif: <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#>\n"+
						"PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n"+
						"SELECT DISTINCT ?phrase ?label ?anno\n"
						+ "WHERE { <"+initialSentence+"> nif:firstWord/nif:nextWord*/nif:subString+ ?phrase.\n"
								+ "OPTIONAL { ?phrase rdfs:label ?label . }\n"
								+ "OPTIONAL { "
								+ "SELECT ?phrase (group_concat(distinct ?val;separator='<BR/>') AS ?anno)\n"
								+ "WHERE { ?phrase ?prop ?val.\n"
								+ "         FILTER isLiteral(?val)\n";
				  if(!keepIDs)
					  query = query   
					  			+ "			FILTER (!regex(str(?prop),'.*[#/]id$'))\n";
				  query=query   + "} GROUP BY ?phrase ORDER BY ?phrase ?rel\n"
								+ "}\n"
						+ "}\n";
						ResultSet phrases = QueryExecutionFactory.create(QueryFactory.create(query), model).execSelect();
						
						while(phrases.hasNext()) {
							QuerySolution phrase = phrases.next();
							System.out.print(escapeURI(phrase.get("phrase"))+" [label=<");
							if(phrase.get("label")==null && phrase.get("anno")==null)
								System.out.print("&nbsp;");
							if(phrase.get("label")!=null)
								System.out.print(escapeLabel(phrase.get("label")));
							if(phrase.get("label")!=null && phrase.get("anno")!=null)
								System.out.print("<BR/>");
							if(phrase.get("anno")!=null)
								//System.out.print("<FONT POINT-SIZE=\"10\">"+phrase.get("anno")+"</FONT>");
								System.out.print(escapeAnno(phrase.get("anno")));
							System.out.println(">];");
						}
				
				// write edges
				query=	"PREFIX nif: <http://persistence.uni-leipzig.org/nlp2rdf/ontologies/nif-core#>\n"+
						"PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n"+
						"PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n"+
						"SELECT DISTINCT ?phrase ?child ?anno\n"
						+ "WHERE { <"+initialSentence+"> nif:firstWord/nif:nextWord*/nif:subString+ ?phrase.\n"
								+ "?child nif:subString ?phrase.\n"
								+ "OPTIONAL { "
								+ "SELECT ?child ?phrase (group_concat(distinct ?val;separator='<BR/>') AS ?anno)\n"
								+ "WHERE { ?child ^rdf:subject ?rel. ?rel rdf:predicate nif:subString; rdf:object ?parent.\n"
								+ "			?rel ?prop ?val.\n"
								+ "         FILTER isLiteral(?val)\n"
								+ "} GROUP BY ?child ?phrase ORDER BY ?child ?phrase ?rel\n"
								+ "}\n"
						+ "}\n";
						phrases = QueryExecutionFactory.create(QueryFactory.create(query), model).execSelect();
						
						while(phrases.hasNext()) {
							QuerySolution phrase = phrases.next();
							System.out.print(escapeURI(phrase.get("phrase"))+" -> "+escapeURI(phrase.get("child"))+" [arrowhead=none");
							if(phrase.get("anno")!=null)
								System.out.print(",xlabel=<"+escapeAnno(phrase.get("anno"))+">");	// xlabel is a little bit more compact than label
							System.out.println("];");
						}

				System.out.println("}");
				  
				System.out.println("}");
			}
		  }
	}

	private static String escapeAnno(RDFNode rdfNode) {
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

		
			
		