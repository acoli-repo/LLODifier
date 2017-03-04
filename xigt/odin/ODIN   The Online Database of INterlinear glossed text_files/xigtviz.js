
function escapeId(id) {
    /*
    From: http://www.w3.org/TR/CSS2/syndata.html
    In CSS, identifiers (including element names, classes, and IDs in
    selectors) can contain only the characters [a-zA-Z0-9] and ISO 10646
    characters U+00A0 and higher, plus the hyphen (-) and the underscore
    (_); they cannot start with a digit, two hyphens, or a hyphen
    followed by a digit. Identifiers can also contain escaped
    characters and any ISO 10646 character as a numeric code (see next
    item). For instance, the identifier "B&W?" may be written as
    "B\&W\?" or "B\26 W\3F".
    */
    function escapeIdChars(id) {
        return Array.prototype.map.call(id, function(c) {
                return /[-_a-zA-Z0-9\u00a0-\uffff]/.test(c) ? c : "\\" + c;
            }).join("")
            .replace(/^(--|-?\d+)/, function(match, c, offset, s){
                return "\\" + c.charCodeAt(0) + " " + c.slice(1);
            });
    }
    if (id.slice(0,1) == "#") return "#" + escapeIdChars(id.slice(1));
    else return escapeIdChars(id);
}

function getattr(obj, attr) {
    return (obj.attributes || {})[attr];
}

function selectItem(igt, itemId) {
    return d3.select(igt).select("[data-id=\"" + itemId + "\"]");
}

var algnexprRe = /([a-zA-Z][\-.\w]*)(\[[^\]]*\])?|\+|,/g;
var spanRe = /-?\d+:-?\d+|\+|,/g;

function alignmentExpressionIds(alex) {
    var ids = [], aeMatch;
    while ((aeMatch = algnexprRe.exec(alex)) !== null) {
        var aeFull = aeMatch[0],
            aeId = aeMatch[1],
            aeSpans = aeMatch[2];
        if (aeId) ids.push(aeId);
    }
    return ids;
}

function alignmentExpressionSpans(alex) {
    var spans = [], aeMatch, spanMatch;
    while ((aeMatch = algnexprRe.exec(alex)) !== null) {
        var aeFull = aeMatch[0],
            aeId = aeMatch[1],
            aeSpans = aeMatch[2];
        if (aeFull == "+" || aeFull == ",") {  // operator
            spans.push({"operator": aeFull})
        } else if (aeSpans === undefined) {  // id without span
            spans.push({"id": aeId})
        } else { // id with span
            while ((spanMatch = spanRe.exec(aeSpans)) !== null) {
                var span = spanMatch[0];
                if (span == "+" || span == ",") {
                    spans.push({"operator": span});
                } else {
                    indices = span.split(":");
                    var start = parseInt(indices[0]),
                        end = parseInt(indices[1]);
                    spans.push({"id": aeId, "span": [start, end]});
                }
            }
        }
    }
    return spans;
}

function resolveAlignmentExpression(igt, alex) {
    var tokens = [];
    alignmentExpressionSpans(alex).forEach(function(aeTerm) {
        if (aeTerm.operator == "+") {
            tokens.push("");  // not necessary; here in case of extensions
        } else if (aeTerm.operator == ",") {
            tokens.push(" ");
        } else {
            var s = getItemContent(igt, escapeId(aeTerm.id));
            if (aeTerm.span !== undefined) {
                s = s.slice(aeTerm.span[0], aeTerm.span[1]);
            }
            tokens.push(s);
        }
    })
    return tokens.join("");
}

function highlightReferents(igt, d, direct) {
    (settings.reference_attributes || []).forEach(function(refAttr) {
        refAttr = refAttr.name;
        if (getattr(d, refAttr) == null) return;
        aeSpans = alignmentExpressionSpans(getattr(d, refAttr));
        if (aeSpans == null) return;
        var spans = {};
        aeSpans.forEach(function(term) {
            if (term.id == null) return;
            if (term.operator != null) return;  // operators don't matter here
            if (spans[term.id] == null) spans[term.id] = [];
            spans[term.id].push(term.span);
        });
        for (var itemId in spans) {
            if (spans.hasOwnProperty(itemId)) {
                applySpans(igt, itemId, spans[itemId], refAttr, direct);
            }

        }
    });
}

function applySpans(igt, itemId, spans, spanclass, direct) {
    var text, chars, spanOn, length;
    selectItem(igt, itemId)
        .classed({"inherited": true, "referenced": direct})
        .html(function(d) {
            text = d._cache.text || getItemContent(igt, itemId);
            length = text.length;
            chars = Array.apply(null, new Array(length))
                        .map(Number.prototype.valueOf,0);
            (spans || []).forEach(function(span) {
                if (span == null) span = [0, length];
                span = normRange(span[0], span[1], length);
                for (i = span[0]; i < span[1]; i++) {
                    chars[i] += 1;
                }
            });
            spanOn = false;
            chars = chars.map(function(c, i) {
                var s = "";
                if (c > 0 && !spanOn) {
                    spanOn = true;
                    s = "<span class=\"refattr-" + spanclass + "\">";
                } else if (c == 0 && spanOn) {
                    spanOn = false;
                    s = "</span>";
                }
                s += text[i];
                if (i == length-1 && spanOn) s += "</span>";
                return s;
            })
            return chars.join("");
        })
        .each(function(d) { highlightReferents(igt, d, false); });
}

function normRange(start, end, length) {
    start = start >= 0 ? start : length - start;
    end = end >= 0 ? end : length - end;
    if (end < start) {
        var tmp = start;
        start = end;
        end = tmp;
    }
    return [start, end];
}

function dehighlightReferents(igt) {
    d3.select(igt).selectAll("div.item.inherited")
        .text(function(d) {
            return d._cache.text || getItemContent(igt, escapeId(d.id));
         })
        .classed({"inherited": false, "referenced": false});
}

function getItemContent(igt, itemId) {
    var item = selectItem(igt, itemId);
    var itemData = item.datum();
    var content;
    if (itemData.text !== undefined)
        content = itemData.text;
    else if (getattr(itemData, "content") !== undefined)
        content = resolveAlignmentExpression(igt, getattr(itemData, "content"));
    else if (getattr(itemData, "segmentation") !== undefined)
        content = resolveAlignmentExpression(igt, getattr(itemData, "segmentation"));
    // last resort, get the displayed text (is this a good idea?)
    else
        content = item.text();
        // if still nothing, go with default
        if (!content) content = settings.default_content || "";
    itemData._cache.text = content;  // needs to be invalidated if it changes
    return content;
}

function tierClasses(tier) {
    var classes = ["tier"];
    if (tier.class) {
        classes.push.apply(tier.class.split());
    }
    return classes;
}

function getTierClass(t) {
    return (settings.tier_types[t.type] || {}).class ||
            settings.default_tier_class;
}

function getContainedIds(col) {
    var ids = [];
    if (col.id) ids.push(col.id);
    (col.children || []).forEach(function(row) {
        row.forEach(function(subcol) {
            ids = ids.concat(subcol.ids);
        })
    });
    return ids;
}

function getContainedTierIds(col) {
    var ids = [];
    if (col.tierId) ids.push(col.tierId);
    (col.children || []).forEach(function(row) {
        row.forEach(function(subcol) {
            ids = ids.concat(subcol.tierIds);
        })
    });
    return d3.set(ids).values();
}


function mergeColumns(cols) {
    // make a new column that contains cols on the first row
    var col = {"children": [[cols]]};
    col.ids = getContainedIds(col);
    col.tierIds = getContainedTierIds(col);
    return col;
}

function hasIntersection(s1, s2) {
    var i, j;
    for (i=0; i<s1.length; i++) {
        for (j=0; j<s2.length; j++) {
            if (s1[i] == s2[j]) return true;
        }
    }
    return false;
}

function findColSpan(agendum, cols, offset) {
    var start = -1, end = -1, i;
    for (i=offset; i<cols.length; i++) {
        if (hasIntersection(agendum.targets, cols[i].ids || [])) {
            start = i; break;
        }
    }
    if (start < 0)
        return null;
    for (end=start+1; end<cols.length; end++) {
        if (! hasIntersection(agendum.targets, cols[end].ids || [])) break;
    }
    return {"start": start, "end": end}
}

function interlinearizationAgenda(items) {
    var curIds = [], itemIds, agenda = [], curgrp;
    items.forEach(function(item) {
        itemIds = alignmentExpressionIds(item.algnexpr);
        if (curIds.length && itemIds && hasIntersection(curIds, itemIds)) {
            curIds = curIds.concat(itemIds);
            curgrp = agenda[agenda.length-1];
            curgrp.items.push(item);
            curgrp.targets = d3.set(curIds).values();
        } else {
            curIds = itemIds || [];
            agenda.push({"items": [item], "targets": d3.set(curIds).values()});
        }
    });
    return agenda;
}

function appendItemsToColumn(col, items) {
    if (col.children === undefined) col.children = [];
    col.children.push(items);
    col.ids = getContainedIds(col);
    col.tierIds = getContainedTierIds(col);
}

function interlinearizeItems(agendum, cols) {
    var col, row, span, maxDepth, colChild, subCols;
    if (cols.length > 1) {
        // more than one column aligned; merge and descend no further
        col = mergeColumns(cols);
        appendItemsToColumn(col, agendum.items);
    } else {
        // 1 column (should never be 0 columns)
        col = cols[0];
        if (col === undefined) { console.log("warning: unspecified col"); }
        if (agendum.targets == col.id || col.children === undefined) {
            // we've arrived at our destination or there's nowhere else to go;
            // just append to the children
            appendItemsToColumn(col, agendum.items);
        } else {
            // descend on the last row
            row = col.children[col.children.length - 1];
            span = findColSpan(agendum, row, 0);
            // there should be a matching span; if not, just make it all
            if (!span) span = {"start": 0, "end": row.length};
            row = d3.merge([
                row.slice(0, span.start),
                [interlinearizeItems(
                    agendum,
                    row.slice(span.start, span.end)
                )],
                row.slice(span.end)
            ])
            // don't forget to reassign the original
            col.children[col.children.length - 1] = row;
            col.ids = getContainedIds(col);
            col.tierIds = getContainedTierIds(col);
        }
    }
    return col;
}

function makeItemCol(item, tier) {
    return {
        "item": item,
        "id": item.id,
        "ids": [item.id],  // ids of all contained children (if any)
        "tierId": tier.id,
        "tierIds": [tier.id],  // tier ids of all contained children
        "algnexpr": getattr(item, "alignment") || getattr(item, "segmentation")
    };
}

function plungeItemCol(ics, depth) {
    // "plunge" as in "make deeper"
    var children = [], itemcol;
    for (; depth > 0; depth--) children.push([]);
    children.push(ics);
    itemcol = {"children": children};
    itemcol.ids = getContainedIds(itemcol);
    itemcol.tierIds = getContainedTierIds(itemcol);
    return itemcol;
}

function padItemCols(ic, ignoreIds) {
    // just descend to the last node and add a new empty row as a child
    if (ic.children == null) {
        if (!ignoreIds.has(ic.id)) ic.children = [[{"skip": true}]];
    } else {
        ic.children[ic.children.length - 1].forEach(function(child) {
            padItemCols(child, ignoreIds);
        });
    }
}

function interlinearizeTier(t, tg) {
    var ics = t.items.map(function(i) { return makeItemCol(i, t); }),
        added = d3.set(),
        tgIdx = 0,
        delay = [],
        colspan;
    (interlinearizationAgenda(ics) || []).forEach(function(agendum) {
        colspan = findColSpan(agendum, tg.children, tgIdx);
        if (colspan !== null) {
            while (delay.length) {
                tg.children.splice(colspan.start, 0,
                    plungeItemCol(delay.shift().items, tg.tiers.length)
                );
                // this changes the size of the array, so adjust colspan
                colspan.start++;
                colspan.end++;
            }
            // now add new items (align to as many columns as necessary)
            tg.children.splice(colspan.start, (colspan.end - colspan.start),
                interlinearizeItems(
                    agendum, tg.children.slice(colspan.start, colspan.end)
            ));
            agendum.items.forEach(function(i) { added.add(i.id); });
        } else {
            delay.push(agendum);
        }
    });
    // Pad leaf items that weren't added to (to keep depth consistent)
    for (i=0; i<tg.children.length; i++) padItemCols(tg.children[i], added);
    // If there's any delayed items, add them
    while (delay.length)
        tg.children.push(plungeItemCol(delay.shift().items, tg.tiers.length));
    // finally update the tier group
    tg.tiers.push(t);
    if (t.id) tg.tierIds.push(t.id);
    // nothing to return
}

function interlinearizable(t, tg) {
    var tgt = getattr(t, "alignment") || getattr(t, "segmentation");
    return (
        t.class == "interlinear" &&
        tg &&
        tgt &&
        tg.tierIds.indexOf(tgt) >= 0
    );
}

function tierGroupFromTier(t) {
    return {
        "tiers": [t],
        "tierIds": [t.id],
        "class": getTierClass(t),
        "children": t.items.map(function(i) { return makeItemCol(i, t); })
    };
}

function computeTierGroups(igtData) {
    var groups = [], curgrp, igroups, t_type;
    igtData.tiers.forEach(function(t) {
        t_type = settings.tier_types[t.type];
        if (t_type) t.class = t_type.class;
        if (interlinearizable(t, curgrp))
            interlinearizeTier(t, groups[groups.length-1]);
        else {
            groups.push(tierGroupFromTier(t));
            curgrp = t.class == "interlinear" ? groups[groups.length-1] : null;
        }
    });
    return groups;
}

// function populateItemGroup(ig, igData) {
//     var rows, coldiv, data = [];
//     if (igData.id) data.push(igData.item);
//     data = data.concat(igData.children || []);
//     rows = ig.selectAll(".row")
//         .data(data)
//       .enter().append("div")
//         .classed("row", true)
//         .each(function(d) {
//             if (d.id) {
//                 cols = d3.select(this).selectAll(".item")
//                     .data([d])
//                   .enter().append("div")
//                     .classed("item", true)
//                     .attr("data-id", d.id)
//                     .attr("data-tier-id", d.tierId);
//             } else if (d.length) {
//                 d3.select(this).selectAll(".col")
//                     .data(d)
//                   .enter().append("div").classed("col", true)
//                     .append("div").classed("subgroup", true)
//                     .each(function(d) {
//                         populateItemGroup(d3.select(this), d);
//                     });
//             }
//         });
// }

function populateItemGroup(ig, igData) {
    var rows, coldiv;
    if (igData.skip) {
        ig.append("div").classed("skip", true).html("&nbsp;")
    } else if (igData.id) {
        ig.selectAll(".item")
            .data([igData.item])
          .enter().append("div").classed("item", true)
            .attr("data-id", function(d) { return d.id; })
            .attr("data-tier-id", function(d) { return d.tierId; });
    }
    rows = ig.selectAll(".row")
        .data(igData.children || [])
      .enter().append("div")
        .classed("row", true)
        .each(function(d) {
            if (d.length) {
                d3.select(this).selectAll(".col")
                    .data(d)
                  .enter().append("div").classed("col", true)
                    .each(function(d) {
                        populateItemGroup(d3.select(this), d);
                    });
            }
        });
}


function populateTierGroup(tg, tgData) {
    // Xigt info about tier goes in the corresponding header
    var header = tg.append("div").classed("tiergroup-header", true);
    header.selectAll("div.tier-header")
        .data(tgData.tiers)
      .enter().append("div").classed("tier-header", true)
        .append("div").classed("tier", true)
        .attr("data-tier-id", function(d) { return d.id; })
        .text(function(d) { return d.type || "(anonymous)"; });
    // (possibly nested) item groups go in the content block
    var content = tg.append("div")
        .classed("tiergroup-content", true);
    content.selectAll(".itemgroup")
        .data(tgData.children)
      .enter().append("div")
        .classed("itemgroup", true)
        .each(function(d) { populateItemGroup(d3.select(this), d); });
}

function igtLayout(elemId, igtData) {
    elemId = escapeId(elemId);
    var igt = d3.select(elemId);
    //var igroups = interlinearItemGroups(tgroups);
    var tiergroups = igt.selectAll(".tiergroup")
        .data(computeTierGroups(igtData))
      .enter().append('div')
        .attr("class", function(d) { return "tiergroup " + d.class || ""; })
        .each(function(d) { populateTierGroup(d3.select(this), d); });
    igt.selectAll("div.itemgroup div.item")
        .each(function(d) { d._cache = {}; })
        .text(function(d) { return getItemContent(elemId, escapeId(d.id));});
    var items = igt.selectAll("div.item")
        .each(function(d) { d._cache = {}; })  // cache is used for highlighting
        .on("mouseover", function(d) { highlightReferents(elemId, d, true); })
        .on("mouseout", function(d) { dehighlightReferents(elemId); });
    if (settings.show_legend) {
        var legend = igt.append("div")
            .classed("xigtviz-legend", true)
            .text("Key:");
        legend.selectAll("div")
            .data(settings.reference_attributes || [])
          .enter().append("div")
            .attr("class", function(d) { return "refattr-" + d.name; })
            .text(function(d) { return d.name});
    }
}
