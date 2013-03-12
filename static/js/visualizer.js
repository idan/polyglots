// Generated by CoffeeScript 1.4.0
(function() {
  var chord_defaults, chord_diagram, colors, get_language_rank, languages;

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
  };

  languages = [
    {
      "name": "JavaScript",
      "rank": 0,
      "contributors": 6485,
      "contributions": 8343,
      "color": colors.belize_hole
    }, {
      "name": "Ruby",
      "rank": 1,
      "contributors": 11141,
      "contributions": 18026,
      "color": colors.alizarin
    }, {
      "name": "Java",
      "rank": 2,
      "contributors": 4311,
      "contributions": 5184,
      "color": colors.turquoise
    }, {
      "name": "Python",
      "rank": 3,
      "contributors": 6732,
      "contributions": 8785,
      "color": colors.nephritis
    }, {
      "name": "Shell",
      "rank": 4,
      "contributors": 3075,
      "contributions": 3946,
      "color": colors.wisteria
    }, {
      "name": "PHP",
      "rank": 5,
      "contributors": 6174,
      "contributions": 9082,
      "color": colors.peter_river
    }, {
      "name": "C",
      "rank": 6,
      "contributors": 6937,
      "contributions": 18460,
      "color": colors.sunflower
    }, {
      "name": "C++",
      "rank": 7,
      "contributors": 4346,
      "contributions": 5011,
      "color": colors.orange
    }, {
      "name": "Perl",
      "rank": 8,
      "contributors": 2144,
      "contributions": 3224,
      "color": colors.pomegranate
    }, {
      "name": "Obj-C",
      "rank": 9,
      "contributors": 2037,
      "contributions": 2830,
      "color": colors.carrot
    }
  ];

  get_language_rank = function(language) {
    return _.find(languages, function(l) {
      return l.name === language;
    }).rank;
  };

  chord_defaults = {
    width: 500,
    height: 500,
    labels: true,
    symmetric: false,
    lang: null,
    ticks: false
  };

  chord_diagram = function(prefix, el, data, opts) {
    var arc, chord, formatPercent, group, groupPath, groupText, groupTicks, innerRadius, layout, mouseout, mouseover, outerRadius, path, rank, svg, ticks;
    opts = _.defaults(opts || {}, chord_defaults);
    outerRadius = Math.min(opts.width, opts.height) / 2 - 25;
    innerRadius = outerRadius - 24;
    formatPercent = d3.format(".1%");
    arc = d3.svg.arc().innerRadius(innerRadius).outerRadius(outerRadius);
    layout = d3.layout.chord().padding(.04).sortSubgroups(d3.descending).sortChords(d3.ascending);
    path = d3.svg.chord().radius(innerRadius);
    svg = d3.select(el).append("svg").attr("width", opts.width).attr("height", opts.height).classed("chord_diagram", true).append("g").attr("id", "circle").attr("data-prefix", prefix).attr("transform", "translate(" + opts.width / 2 + "," + opts.height / 2 + ")");
    svg.append("circle").attr("r", outerRadius);
    layout.matrix(data);
    mouseover = function(d, i) {
      return chord.classed("fade", function(p) {
        return p.source.index !== i && p.target.index !== i;
      });
    };
    mouseout = function(d, i) {
      chord.classed("fade", false);
      return svg.classed("lockfade", false);
    };
    group = svg.selectAll(".group").data(layout.groups).enter().append("g").attr("class", "group");
    group.append("title").text(function(d, i) {
      return "" + languages[i].name;
    });
    groupPath = group.append("path").attr("id", function(d, i) {
      return "" + prefix + "_group" + i;
    }).attr("d", arc).style("fill", function(d, i) {
      return languages[i].color;
    });
    if (opts.labels) {
      groupText = group.append("text").attr("x", 6).attr("dy", 15);
      groupText.append("textPath").attr("xlink:href", function(d, i) {
        return "#" + prefix + "_group" + i;
      }).text(function(d, i) {
        return languages[i].name;
      });
      groupText.filter(function(d, i) {
        return groupPath[0][i].getTotalLength() / 2 - 16 < this.getComputedTextLength();
      }).remove();
    }
    chord = svg.selectAll(".chord").data(layout.chords).enter().append("path").attr("class", "chord").style("fill", function(d) {
      if (opts.symmetric) {
        return colors.silver;
      } else {
        return languages[d.source.index].color;
      }
    }).attr("d", path);
    if (opts.lang != null) {
      rank = get_language_rank(opts.lang);
      svg.classed("permafade", true);
      chord.classed("fade", function(d, i) {
        return d.source.index !== rank && d.target.index !== rank;
      });
    } else {
      group.on('mouseover', mouseover);
      group.on('mouseout', mouseout);
    }
    if (opts.ticks) {
      groupTicks = function(d) {
        var k;
        k = (d.endAngle - d.startAngle) / d.value;
        return d3.range(0, d.value, 500).map(function(v, i) {
          return {
            angle: v * k + d.startAngle,
            label: i % 2 ? null : "" + (v / 1000.0) + "k"
          };
        });
      };
      ticks = svg.append("g").classed('ticks', true).selectAll("g").data(layout.groups).enter().append("g").selectAll("g").data(groupTicks).enter().append("g").attr("transform", function(d) {
        return "rotate(" + (d.angle * 180 / Math.PI - 90) + ") translate(" + outerRadius + ",0)";
      });
      ticks.append("line").attr("x1", 1).attr("y1", 0).attr("x2", 5).attr("y2", 0).style("stroke", "#000");
      return ticks.append("text").attr("x", 8).attr("dy", "0.35em").attr("transform", function(d) {
        var _ref;
        return (_ref = d.angle > Math.PI) != null ? _ref : {
          "rotate(180)translate(-16)": null
        };
      }).style("text-anchor", function(d) {
        var _ref;
        return (_ref = d.angle > Math.PI) != null ? _ref : {
          "end": null
        };
      }).text(function(d) {
        return d.label;
      });
    }
  };

  $(function() {
    return d3.json("static/data/language_adjacency.json", function(error, data) {
      chord_diagram('repos_all', ".all_polyglots>.vis", data.repos);
      chord_diagram('repos_noself', ".no_self_links>.vis", data.repos_noself);
      chord_diagram('commits_noself', ".by_commits>.vis", data.commits_noself);
      return chord_diagram('chord_commits_people_noself', ".by_people>.vis", data.people_noself, {
        symmetric: true,
        ticks: true
      });
    }, $('a.chordlang').on('click', function(event) {
      var chord, d3svg, rank, svg;
      event.preventDefault();
      rank = get_language_rank($(this).attr('data-lang'));
      svg = $(this).closest('.row').find('#circle');
      d3svg = d3.select(svg[0]);
      d3svg.classed('lockfade', true);
      chord = d3svg.selectAll('.chord');
      return chord.classed("fade", function(p) {
        return p.source.index !== rank && p.target.index !== rank;
      });
    }));
  });

}).call(this);
