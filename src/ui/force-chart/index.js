function createChart(context, id) {
  const canvas = document.createElement("canvas");
  canvas.width = 600;
  canvas.height = 300;

  const contextNode = document.getElementsByTagName(context)[0]; // NB: context needs to be a tag name
  contextNode.appendChild(canvas);

  if (window.window.charts == null) window.charts = {};

  window.charts[id] = new Chart(canvas, {
    type: "line",
    data: {
      labels: [],
      datasets: [
        {
          label: "Force",
          data: [],
          backgroundColor: ["rgba(255, 99, 132, 0.2)"],
          borderColor: ["rgba(255,99,132,1)"],
          borderWidth: 1
        }
      ]
    },
    options: {
      scales: {
        yAxes: [
          {
            ticks: {
              beginAtZero: true,
              suggestedMin: -5,
              suggestedMax: 5
            }
          }
        ]
      }
    }
  });
}

function addData(id, label, data) {
  window.charts[id].data.labels.push(label);
  window.charts[id].data.datasets.forEach(dataset => {
    dataset.data.push(data);
  });
  window.charts[id].update();
}

function shiftData(id) {
  window.charts[id].data.labels.shift();
  window.charts[id].data.datasets.forEach(dataset => {
    dataset.data.shift();
  });
  //window.charts[id].update({ duration: 0 } );
}

function updateSpeed(id, value) {
  document.getElementById("speed_" + id).innerHTML = value;
}

function updateAcceleration(id, value) {
  document.getElementById("acceleration_" + id).innerHTML = value;
}

function addChartData(id, label, force) {
  addData(id, label, force);
}
