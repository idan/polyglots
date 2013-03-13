root = exports ? this

# Interpolating to zero can have bad side-effects:
# https://github.com/mbostock/d3/wiki/Transitions#wiki-d3_interpolateNumber
zeroish = 1e-6

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
    asbestos: "#7f8c8d"
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
    {"name": "Objective-C", "short_name": "Obj-C", "rank": 9, "contributors": 2037, "contributions": 2830, "color": colors.carrot}]

get_language_rank = (language) ->
    return _.find(languages, (l) -> return l.name == language).rank


chord_defaults = {
    width: 500,
    height: 500,
    labels: true,
    symmetric: false, # symmetric colors chords by source on hover,
    lang: null, # pin the chart to a specific language
    ticks: false # whether or not to draw tickmarks
}

chord_diagram = (prefix, el, data, opts) ->
    opts = _.defaults(opts or {}, chord_defaults)
    outerRadius = Math.min(opts.width, opts.height) / 2 - 25
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
        .classed("chord_diagram", true)
      .append("g")
        .attr("id", "circle")
        .attr("data-prefix", prefix)
        .attr("transform", "translate(" + opts.width / 2 + "," + opts.height / 2 + ")")

    svg.append("circle")
        .attr("r", outerRadius)

    # Compute the chord layout.
    layout.matrix(data)

    mouseover = (d, i) ->
        chord.classed("fade", (p) ->
            return p.source.index != i && p.target.index != i
        )

    mouseout = (d, i) ->
        chord.classed("fade", false)
        svg.classed("lockfade", false)

    # Add a group per language.
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
            .text((d, i) ->
                if 'short_name' of languages[i]
                    return languages[i].short_name
                else
                    return languages[i].name
            )


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


    if opts.ticks
        # Returns an array of tick angles and labels, given a group.
        groupTicks = (d) ->
            k = (d.endAngle - d.startAngle) / d.value;
            return d3.range(0, d.value, 500).map((v, i) ->

                return {
                    angle: v * k + d.startAngle,
                    label: if i % 2 then null else "#{v/1000.0}k"
                }
            )

        ticks = svg.append("g")
            .classed('ticks', true)
            .selectAll("g")
            .data(layout.groups)
            .enter().append("g").selectAll("g")
            .data(groupTicks)
            .enter().append("g")
            .attr("transform", (d) ->
                return "rotate(#{(d.angle * 180 / Math.PI - 90)}) translate(#{outerRadius},0)"
            )

        ticks.append("line")
            .attr("x1", 1)
            .attr("y1", 0)
            .attr("x2", 5)
            .attr("y2", 0)
            .style("stroke", "#000")

        ticks.append("text")
            .attr("x", 8)
            .attr("dy", "0.35em")
            .attr("transform", (d) -> return d.angle > Math.PI ? "rotate(180)translate(-16)" : null)
            .style("text-anchor", (d) -> return d.angle > Math.PI ? "end" : null)
            .text((d) -> return d.label)

class D3MultiLanguageChart
    constructor: (@el, @data, @opts) ->
        defaults = {
            width: 1170,
            height: 400,
            paddingY: 20,
            gutterwidth: 10, # width between charts
        }
        @opts = _.defaults(opts or {}, defaults)
        @chartwidth = (@opts.width - ((languages.length - 1) * @opts.gutterwidth)) / languages.length
        @chartheight = @opts.height - (2 * @opts.paddingY)
        @svg = d3.select(@el).append("svg")
                .attr("width", @opts.width)
                .attr("height", @opts.height)
                .append('g')
                .attr("transform", "translate(0,#{@opts.paddingY})")
        @y = d3.scale.linear()
                .range([@opts.height-@opts.paddingY, @opts.paddingY])
        @x = d3.scale.linear()
                .domain([0,199])
                .range([0,@chartwidth])

        @grouped = _.groupBy(@data, 'language')
        @dataByLang = d3.nest()
                        .key((d) -> return d.language)
                        .map(@data)
        @hoverIndex = null
        @render()

    render: (key='contributor_count') ->
        console.log('render!')
        values = _.map(_.without(_.pluck(@data, key), ''), parseInt)
        @y.domain(d3.extent(values))

        # join
        # update
        # enter
        # enter+update
        # exit

        for lang in languages
            @renderlangchart(lang)

    renderlangchart: (lang) ->
        console.log("Render Lang Chart: #{lang.name}")
        data = @dataByLang[lang.name]
        area = d3.svg.area()
                .x((d) => return(@x(d.rank)))
                .y0(@chartheight)
                .y((d) => return(@y(d[key])))

        # join
        chart = @svg.append('g')
                    # .attr('data-lang', lang.name)
                    # .classed('langchart', true)
                    .attr('transform', () =>
                        offset = (lang.rank * @chartwidth) + (lang.rank * @opts.gutterwidth)
                        "translate(#{offset}, 0)")


        chart.append('path')
            .data(data, (d, i) ->
                console.log(d)
                console.log(i)
                return d['_id'])
            .attr('class', 'areachart')
            .attr('d', area)



        # for lang, repos of @grouped
        #     langgroup = @svg    


        # # Add a group per neighborhood.
        # langgroups = @chart.selectAll(".langgroup")
        #     .data(layout.groups)
        #   .enter().append("g")
        #     .attr("class", "group")

        # for language in languages
        #     @svg.

class D3LanguageCharts extends Backbone.View
    defaults: {
        key: 'contributor_count',
        hoverindex: null,
    }

    initialize: ->
        @options = _.extend(@defaults, @options)
        _.bindAll(@)
        @grouped = _.groupBy(@options.data, 'language')
        @charts = []
        @render()

    render: ->
        @$el.empty()
        for lang, repos of @grouped
            console.log("Creating new chart with #{lang}!")
            chart = new D3LanguageChart({
                language: lang, data: repos.slice(),
                fieldmap: @options.fieldmap,
                id: "langchart_#{lang}",
                key: @options.key})
            chart.listenTo(@, 'langchart:keychanged', chart.foo)
            chart.listenTo(@, 'change:hoverindex', chart.foo)
            @$el.append(chart.el)
            @charts.push(chart)
        root.charts = @charts
        return @


    setKey: (key) ->
        if key?
            @options.key = key
            @trigger('langchart:keychanged', @options.key)



class D3LanguageChart extends Backbone.View
    className: 'd3langchart'

    defaults: {
        width: 108,
        height: 400,
        paddingY: 20,
        key: 'contributor_count',
        hoverindex: null,
        # gutterwidth: 10, # width between charts
    }

    initialize: ->
        @options = _.defaults(@options, @defaults)
        _.bindAll(@)
        @chartheight = @options.height - (2 * @options.paddingY)
        @setup()
        @$el.append("<p class=\"name\">#{@options.language}</p>")


    foo: (newkey) ->
        @options.key = newkey
        @render()

    setup: ->
        d3.selectAll(@$el).append("svg")
            .attr("width", @options.width)
            .attr("height", @options.height)
            .append('g')
            .attr("transform", "translate(0,#{@options.paddingY})")
        @render()
        return @

    render: ->
        extents = _.findWhere(@options.fieldmap, {'name': @options.key}).extents
        y = d3.scale.linear()
                .domain(extents)
                .range([@options.height-@options.paddingY, @options.paddingY])
        x = d3.scale.linear()
                .domain([0,199])
                .range([0,@options.width])

        # join
        svg = d3.select(@$el[0]).select('svg>g')

        # points = svg.selectAll('.point')
        #     .data(@options.data)

        # # update
        # # enter
        # points.enter().append('circle')
        #     .on('mouseover', (d,i) =>
        #         console.log("#{d.language} #{d.rank} #{d.user}/#{d.name} #{d[@options.key]}")
        #         )

        # # enter+update
        # points.attr('class', 'point')
        #     .transition()
        #     .attr('r', 2)
        #     .attr('cx', (d,i) -> x(d.rank))
        #     .attr('cy', (d,i) => y(d[@options.key]))

        # # exit


        line = d3.svg.line()
                .x((d,i) => return x(d.rank))
                .y((d) => return(y(d[@options.key])))

        # area = d3.svg.area()
        #         .x((d) => return(@x(d.rank)))
        #         .y0(@chartheight)
        #         .y((d) => return(@y(d[@key])))
        topline = svg.append('path')
            .datum(@options.data)
            .attr('class', 'topline')
            .attr('d', line)
        return @






$ ->
    d3.json("static/data/language_adjacency.json", (error, data) ->
        chord_diagram('repos_all', ".all_polyglots>.vis", data.repos)
        chord_diagram('repos_noself', ".no_self_links>.vis", data.repos_noself)
        chord_diagram('commits_noself', ".by_commits>.vis", data.commits_noself)
        chord_diagram('chord_commits_people_noself', ".by_people>.vis", data.people_noself, {symmetric: true, ticks: true})
    )
    d3.csv("static/data/repos.csv", (error, repos) ->
        d3.json("static/data/repofields.json", (error, fieldmap) ->
            intfields = _.where(fieldmap, {'type': 'int'})
            datefields = _.where(fieldmap, {'type': 'datetime'})
            _.each(repos, (r) ->
                # integerize ints
                for prop in _.pluck(intfields, 'name')
                    if prop of r
                        r[prop] = parseInt(r[prop]) or 0
                    else
                        r[prop] = 0

                # dateize dates
                for prop in _.pluck(datefields, 'name')
                    if prop of r
                        r[prop] = Date(r[prop]) or Date(0)
                    else
                        r[prop] = Date(0)
            )

            root.langcharts = new D3LanguageCharts({
                data: repos,
                fieldmap: fieldmap,
                el: $(".all_languages>.vis")})
            root.repos = repos
            root.fieldmap = fieldmap
        )

    )

    # focus a chord chart on a specific language
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
