// Create a DataSet (allows two way data-binding)
var items = new vis.DataSet([
    {id: 1, content: 'Grow', start: 0, end: 1000, editable: true, group: 1},
    {id: 2, content: 'Shrink', start: 1000, end: 3000, editable: true, group: 1},
    {id: 3, content: 'Grow', start: 0, end: 1000, editable: true, group: 2},
    {id: 4, content: 'Shrink', start: 1000, end: 3000, editable: true, group: 2},
    {id: 5, content: 'Grow', start: 0, end: 1000, editable: true, group: 3},
    {id: 6, content: 'Shrink', start: 1000, end: 3000, editable: true, group: 3}
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
    var timeline = new vis.Timeline(container, items, groups, options);
});
