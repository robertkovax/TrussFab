var timeline;

// Create a DataSet (allows two way data-binding)
var items = new vis.DataSet([
    {id: 1, content: 'Grow', start: 0, end: 1000, editable: true, group: 1},
    {id: 2, content: 'Shrink', start: 1000, end: 3000, editable: true, group: 1},
]);

var groups = [
    {
        id: 1,
        content: 'Actuator 1'
        // Optional: a field 'className', 'style', 'order', [properties]
    },
    {
        id: 2,
        content: 'Actuator 2'
        // Optional: a field 'className', 'style', 'order', [properties]
    },
    {
        id: 3,
        content: 'Actuator 3'
        // Optional: a field 'className', 'style', 'order', [properties]
    }
    // more groups...
];

$(document).ready(function() {
    var container = document.getElementById('visualization');

    // Configuration for the Timeline
    var options = {
        start: 0,
        end: 10000,
        min: 0,
        max: 70000,
        zoomMin: 1000,
        showCurrentTime: false,
        editable: true,
        format: {
            minorLabels: {
                millisecond: 'SSS',
                second: 's',
                minute: '',
                hour: '',
                weekday: '',
                day: '',
                week: '',
                month: '',
                year: ''
            },
            majorLabels: {
                millisecond: 'SSS',
                second: 's',
                minute: '',
                hour: '',
                weekday: '',
                day: '',
                week: '',
                month: '',
                year: ''
            }
        }
    };

    // Create a Timeline
    timeline = new vis.Timeline(container, items, options);
});


var id = 3;

function add_box() {
    items.add({id: id, content: 'Grow', start: 0, end: 1000, editable: true, group: 1});
    id++;
}
