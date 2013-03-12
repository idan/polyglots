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

get_language_rank = (language) ->
    return _.find(languages, (l) -> return l.name == language).rank


chord_defaults = {
    width: 500,
    height: 500,
    labels: true,
    symmetric: false, # symmetric colors chords by source on hover,
    lang: null # pin the chart to a specific language
}

chord_diagram = (prefix, el, data, opts) ->
    opts = _.defaults(opts or {}, chord_defaults)
    outerRadius = Math.min(opts.width, opts.height) / 2 - 10
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

    svg = d3.select(el).append("svg")
        .attr("width", opts.width)
        .attr("height", opts.height)
      .append("g")
        .attr("id", "circle")
        .attr("data-prefix", prefix)
        .attr("transform", "translate(" + opts.width / 2 + "," + opts.height / 2 + ")")

    svg.append("circle")
        .attr("r", outerRadius)

    # Compute the chord layout.
    layout.matrix(data)

    mouseover = (d, i) ->
        console.log('mouseover')
        chord.classed("fade", (p) ->
            return p.source.index != i && p.target.index != i
        )

    mouseout = (d, i) ->
        console.log('mouseout')
        chord.classed("fade", false)
        svg.classed("lockfade", false)

    # Add a group per neighborhood.
    group = svg.selectAll(".group")
        .data(layout.groups)
      .enter().append("g")
        .attr("class", "group")

    # Add a mouseover title to the arcs
    group.append("title").text((d, i) -> return "#{languages[i].name}")

    # Add the group arc.
    groupPath = group.append("path")
        .attr("id", (d, i) -> return "#{prefix}_group#{i}")
        .attr("d", arc)
        .style("fill", (d, i) -> return languages[i].color)


    if opts.labels
        # Add a text label.
        groupText = group.append("text")
            .attr("x", 6)
            .attr("dy", 15)

        groupText.append("textPath")
            .attr("xlink:href", (d, i) -> return "##{prefix}_group#{i}")
            .text((d, i) -> return languages[i].name );

        # Remove the labels that don't fit
        groupText.filter((d, i) ->
            return groupPath[0][i].getTotalLength() / 2 - 16 < this.getComputedTextLength())
            .remove();

    # Add the chords.
    chord = svg.selectAll(".chord")
        .data(layout.chords)
      .enter().append("path")
        .attr("class", "chord")
        .style("fill", (d) ->
            if opts.symmetric
                return colors.silver
            else
                return languages[d.source.index].color
        )
        .attr("d", path);

    # # Add an elaborate mouseover title for each chord.
    # chord.append("title").text((d) -> return languages[d.source.index].name)

    if opts.lang?
        rank = get_language_rank(opts.lang)
        svg.classed("permafade", true)
        chord.classed("fade", (d, i) ->
            return d.source.index != rank && d.target.index != rank
        )
    else
        group.on('mouseover', mouseover)
        group.on('mouseout', mouseout)


$ ->
    d3.json("static/data/language_adjacency.json", (error, data) ->
        chord_diagram('repos_all', ".all_polyglots>.vis", data.repos)
        chord_diagram('repos_noself', ".no_self_links>.vis", data.repos_noself)
        chord_diagram('commits_noself', ".by_commits>.vis", data.commits_noself)


    $('a.chordlang').on('click', (event) ->
        event.preventDefault()
        rank = get_language_rank($(this).attr('data-lang'))
        svg = $(this).closest('.row').find('#circle')
        d3svg = d3.select(svg[0])
        d3svg.classed('lockfade', true)
        chord = d3svg.selectAll('.chord')
        chord.classed("fade", (p) ->
            return p.source.index != rank && p.target.index != rank
        )
    )
        # chord_diagram('chord_cpp_small', ".chord_cpp>.vis", data.repos, {width: 300, height: 300, labels: false, lang: 'Shell'})
        # chord_diagram('chord_ruby_small', ".chord_ruby>.vis", data.repos, {width: 300, height: 300, labels: false, lang: 'Ruby'})
        # chord_diagram('chord_commits', "#polyglot_tendencies>.vis", data.commits)
        # chord_diagram('chord_repos_noself', "#polyglot_tendencies>.vis", data.repos_noself)
        # chord_diagram('chord_commits_noself', "#polyglot_tendencies>.vis", data.commits_noself)
        # chord_diagram('chord_commits_noself_small', "#polyglot_tendencies>.vis", data.commits_noself, {width: 200, height: 200, labels: false, lang: 'Python'})
        # chord_diagram('chord_commits_people', "#polyglot_tendencies>.vis", data.people, {symmetric: true, lang: 'Java'})
        # chord_diagram('chord_commits_people_noself', "#polyglot_tendencies>.vis", data.people_noself, {symmetric: true})


    )