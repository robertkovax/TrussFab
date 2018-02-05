var ctx = document.getElementById("forceChart");
var forceChart = new Chart(ctx, {
    type: 'line',
    data: {
        labels: [],
        datasets: [{
            label: 'Force of Actuator',
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

function addData(label, data) {
    forceChart.data.labels.push(label);
    forceChart.data.datasets.forEach((dataset) => {
        dataset.data.push(data);
    });
    forceChart.update();
}

function shiftData() {
    forceChart.data.labels.shift();
    forceChart.data.datasets.forEach((dataset) => {
        dataset.data.shift();
    });
    //forceChart.update({ duration: 0 } );
}
