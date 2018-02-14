var id = document.currentScript.getAttribute('id');
// TODO: Find a way to persist this charts map
var ctx = document.getElementById("forceChart_" + id);
charts.id = new Chart(ctx, {
    type: 'line',
    data: {
        labels: [],
        datasets: [{
            label: 'Force',
            data: [],
            backgroundColor: [
                'rgba(255, 99, 132, 0.2)'
            ],
            borderColor: [
                'rgba(255,99,132,1)'
            ],
            borderWidth: 1
        }]
    },
    options: {
        scales: {
            yAxes: [{
                ticks: {
                    beginAtZero:true,
                    suggestedMin: -5,
                    suggestedMax: 5
                }
            }]
        }
    }
});

function addData(id, label, data) {
    charts.id.data.labels.push(label);
    charts.id.data.datasets.forEach((dataset) => {
        dataset.data.push(data);
    });
    charts.id.update();
}

function shiftData(id) {
    charts.id.data.labels.shift();
    charts.id.data.datasets.forEach((dataset) => {
        dataset.data.shift();
    });
    //charts[id].update({ duration: 0 } );
}
