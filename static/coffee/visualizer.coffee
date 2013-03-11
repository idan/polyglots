colors = {
    turquoise: "#1abc9c",
    green_sea: "#16a085",
    emerland: "#2ecc71",
    nephritis: "#27ae60",
    peter_river: "#3498db",
    belize_hole: "#2980b9",
    amethyst: "#9b59b6",
    wisteria: "#8e44ad",
    wet_asphalt: "#34495e",
    midnight_blue: "#2c3e50",
    sunflower: "#f1c40f",
    orange: "#f39c12",
    carrot: "#e67e22",
    pumpkin: "#d35400",
    alizarin: "#e74c3c",
    pomegranate: "#c0392b",
    clouds: "#ecf0f1",
    silver: "#bdc3c7",
    concrete: "#95a5a6",
    asbestos: "#7f8c8d",
}


# There were 44,389 github contributors for the top 2k repos
# contributors: how many of that set contributed to a language
# contributions: how many commits were made by those contributors
# contributors: of all the contributors to the top 2k repos, how many contributed
languages = [
    {"name": "JavaScript", "rank": 0, "contributors": 6485, "contributions": 8343, "color": colors.belize_hole},
    {"name": "Ruby", "rank": 1, "contributors": 11141, "contributions": 18026, "color": colors.alizarin},
    {"name": "Java", "rank": 2, "contributors": 4311, "contributions": 5184, "color": colors.turquoise},
    {"name": "Python", "rank": 3, "contributors": 6732, "contributions": 8785, "color": colors.nephritis},
    {"name": "Shell", "rank": 4, "contributors": 3075, "contributions": 3946, "color": colors.wisteria},
    {"name": "PHP", "rank": 5, "contributors": 6174, "contributions": 9082, "color": colors.peter_river},
    {"name": "C", "rank": 6, "contributors": 6937, "contributions": 18460, "color": colors.sunflower},
    {"name": "C++", "rank": 7, "contributors": 4346, "contributions": 5011, "color": colors.orange},
    {"name": "Perl", "rank": 8, "contributors": 2144, "contributions": 3224, "color": colors.pomegranate},
    {"name": "Obj-C", "rank": 9, "contributors": 2037, "contributions": 2830, "color": colors.carrot}]

polyglot_matrix =
    [[8343, 2796, 249, 724, 533, 910, 665, 339, 197, 155],
     [1642, 18026, 435, 1035, 1111, 703, 1248, 394, 441, 511],
     [271, 663, 5184, 301, 305, 131, 442, 155, 67, 67],
     [629, 1079, 269, 8785, 579, 309, 1113, 292, 215, 158],
     [789, 2375, 332, 638, 3946, 424, 924, 241, 145, 127],
     [716, 562, 79, 316, 223, 9082, 274, 100, 108, 98],
     [594, 1669, 293, 780, 551, 300, 18460, 667, 469, 232],
     [479, 690, 178, 367, 269, 202, 1652, 5011, 195, 99],
     [167, 470, 61, 240, 170, 128, 764, 110, 3224, 73],
     [162, 629, 88, 258, 128, 74, 217, 83, 76, 2830]]

 polyglot_matrix_noself =
     [[0, 2796, 249, 724, 533, 910, 665, 339, 197, 155],
      [1642, 0, 435, 1035, 1111, 703, 1248, 394, 441, 511],
      [271, 663, 0, 301, 305, 131, 442, 155, 67, 67],
      [629, 1079, 269, 0, 579, 309, 1113, 292, 215, 158],
      [789, 2375, 332, 638, 0, 424, 924, 241, 145, 127],
      [716, 562, 79, 316, 223, 0, 274, 100, 108, 98],
      [594, 1669, 293, 780, 551, 300, 0, 667, 469, 232],
      [479, 690, 178, 367, 269, 202, 1652, 0, 195, 99],
      [167, 470, 61, 240, 170, 128, 764, 110, 0, 73],
      [162, 629, 88, 258, 128, 74, 217, 83, 76, 0]]



$ ->
    console.log('domready!')

    width = 600
    height = 600
    outerRadius = Math.min(width, height) / 2 - 10
    innerRadius = outerRadius - 24

    formatPercent = d3.format(".1%")

    arc = d3.svg.arc()
        .innerRadius(innerRadius)
        .outerRadius(outerRadius)

    layout = d3.layout.chord()
        .padding(.04)
        .sortSubgroups(d3.descending)
        .sortChords(d3.ascending)

    path = d3.svg.chord()
        .radius(innerRadius)

    svg = d3.select("#polyglot_tendencies>.vis").append("svg")
        .attr("width", width)
        .attr("height", height)
      .append("g")
        .attr("id", "circle")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")")

    svg.append("circle")
        .attr("r", outerRadius)

    # Compute the chord layout.
    layout.matrix(polyglot_matrix_noself)

    mouseover = (d, i) ->
        console.log("hover!")
        chord.classed("fade", (p) ->
            return p.source.index != i && p.target.index != i
        )

    # Add a group per neighborhood.
    group = svg.selectAll(".group")
        .data(layout.groups)
      .enter().append("g")
        .attr("class", "group")
        .on("mouseover", mouseover)

    # Add a mouseover title.
    group.append("title").text((d, i) -> return "#{languages[i].name}: #{d}")

    # Add the group arc.
    groupPath = group.append("path")
        .attr("id", (d, i) -> return "group" + i)
        .attr("d", arc)
        .style("fill", (d, i) -> return languages[i].color)

    # Add a text label.
    groupText = group.append("text")
        .attr("x", 6)
        .attr("dy", 15)

    groupText.append("textPath")
        .attr("xlink:href", (d, i) -> return "#group#{i}")
        .text((d, i) -> return languages[i].name );

    # Add the chords.
    chord = svg.selectAll(".chord")
        .data(layout.chords)
      .enter().append("path")
        .attr("class", "chord")
        .style("fill", (d) -> return languages[d.source.index].color )
        .attr("d", path);




    # d3.csv("cities.csv", function(cities) {
    #   d3.json("matrix.json", function(matrix) {

    #     # Compute the chord layout.
    #     layout.matrix(matrix);

    #     # Add a group per neighborhood.
    #     group = svg.selectAll(".group")
    #         .data(layout.groups)
    #       .enter().append("g")
    #         .attr("class", "group")
    #         .on("mouseover", mouseover);

    #     # Add a mouseover title.
    #     group.append("title").text(function(d, i) {
    #         return "#{languages[i].name}: #{d}"
    #     });

    #     # Add the group arc.
    #     groupPath = group.append("path")
    #         .attr("id", function(d, i) { return "group" + i; })
    #         .attr("d", arc)
    #         .style("fill", function(d, i) { return cities[i].color; });

    #     # Add a text label.
    #     groupText = group.append("text")
    #         .attr("x", 6)
    #         .attr("dy", 15);

    #     groupText.append("textPath")
    #         .attr("xlink:href", function(d, i) { return "#group" + i; })
    #         .text(function(d, i) { return cities[i].name; });

    #     # Remove the labels that don't fit. :(
    #     groupText.filter(function(d, i) { return groupPath[0][i].getTotalLength() / 2 - 16 < this.getComputedTextLength(); })
    #         .remove();

    #     # Add the chords.
    #     chord = svg.selectAll(".chord")
    #         .data(layout.chords)
    #       .enter().append("path")
    #         .attr("class", "chord")
    #         .style("fill", function(d) { return cities[d.source.index].color; })
    #         .attr("d", path);

    #     # Add an elaborate mouseover title for each chord.
    #     chord.append("title").text(function(d) {
    #       return cities[d.source.index].name
    #           + " → " + cities[d.target.index].name
    #           + ": " + formatPercent(d.source.value)
    #           + "\n" + cities[d.target.index].name
    #           + " → " + cities[d.source.index].name
    #           + ": " + formatPercent(d.target.value);
    #     });

    #     function mouseover(d, i) {
    #       chord.classed("fade", function(p) {
    #         return p.source.index != i
    #             && p.target.index != i;
    #       });
    #     }
    #   });
    # });