function createEdgeChart(context, id) {
  const canvas = document.createElement("canvas");
  canvas.width = 600;
  canvas.height = 300;

  const contextNode = document.getElementsByTagName(context)[0]; // NB: context needs to be a tag name
  contextNode.appendChild(canvas);

  if (window.window.charts == null) window.charts = {};

  window.charts["Edge" + id] = new Chart(canvas, {
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

function createHubChart(context, id) {
  const canvas = document.createElement("canvas");
  canvas.width = 600;
  canvas.height = 300;

  const contextNode = document.getElementsByTagName(context)[0]; // NB: context needs to be a tag name
  contextNode.appendChild(canvas);

  if (window.window.charts == null) window.charts = {};

  window.charts["Hub" + id] = new Chart(canvas, {
    type: "line",
    data: {
      labels: [],
      datasets: [
        {
          label: "Speed",
          data: [],
          backgroundColor: ["rgba(255, 99, 132, 0.2)"],
          borderColor: ["rgba(255, 99, 132, 1)"],
          borderWidth: 1
        },
        {
          label: "Acceleration",
          data: [],
          backgroundColor: ["rgba(51, 153, 255, 0.2)"],
          borderColor: ["rgba(51, 153, 255,1)"],
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

function shiftData(id) {
  window.charts[id].data.labels.shift();
  window.charts[id].data.datasets.forEach(dataset => {
    dataset.data.shift();
  });
}

function addChartData(id, label, data, datatype, sensortype) {
  var filteredDataset =
    window.charts[sensortype+id].data.datasets.filter(dataset => {
    return dataset.label == datatype;
  });
  if(filteredDataset.length == 0) return;
  filteredDataset[0].data.push(data);
}

function updateChart(id, sensortype, label) {
  window.charts[sensortype+id].data.labels.push(label);
  window.charts[sensortype+id].update();
}
