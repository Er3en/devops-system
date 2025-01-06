package main

import (
	"fmt"
	"log"
	"os"
	"path"

	"gopkg.in/yaml.v2"
	"helm.sh/helm/v3/pkg/chart/loader"
	"helm.sh/helm/v3/pkg/chartutil"
)

type Helm struct {
	ChartName string
	OutputDir string
	ChartPath string
}

func (h *Helm) CreateChart() (string, error) {

	if _, err := os.Stat(h.OutputDir); os.IsNotExist(err) {
		fmt.Println("Directory does no texist, creating:", h.OutputDir)
		err := os.MkdirAll(h.OutputDir, 0755)
		if err != nil {
			log.Fatalf("Failed to create output directory: %v", err)
		}
	}

	chartPath, err := chartutil.Create(h.ChartName, h.OutputDir)
	if err != nil {
		return "", fmt.Errorf("error creating Helm chart: %v", err)
	}

	return chartPath, nil

}

func (h *Helm) Render() error {

	fmt.Printf(h.ChartPath)
	// Load the Helm chart from the directory
	chart, err := loader.Load(h.ChartPath)
	if err != nil {
		log.Fatalf("Error loading Helm chart: %v", err)
	}

	// Your custom values for the chart
	chrtVals := map[string]interface{}{
		"replicaCount": 3,
		"image": map[string]interface{}{
			"repository": "nginx",
			"tag":        "latest",
		},
	}

	// Release options (customize as needed)
	options := chartutil.ReleaseOptions{
		Name:      "my-release",
		Namespace: "default",
	}

	// Capabilities (optional, can be nil if not needed)
	caps := &chartutil.Capabilities{
		KubeVersion: chartutil.KubeVersion{Version: "v1.18.0"},
	}

	// Render values
	renderValues, err := chartutil.ToRenderValues(chart, chrtVals, options, caps)
	if err != nil {
		log.Fatalf("Error rendering values: %v", err)
	}

	// Marshal the rendered values into YAML format
	yamlData, err := yaml.Marshal(renderValues)
	if err != nil {
		log.Fatalf("Error marshaling to YAML: %v", err)
	}

	// Print the rendered values in YAML format
	fmt.Println(string(yamlData))
	return nil

	//chartutil.ToRenderValues()
}

func main() {

	helm := Helm{
		ChartName: "test1",
		OutputDir: "./k8s",
	}
	helm.ChartPath = path.Join(helm.OutputDir, helm.ChartName)

	err := helm.Render()

	if err != nil {
		log.Fatalf("Error render %v", err)
	}

	// // Create the Helm chart
	// chartPath, err := helm.CreateChart()
	// if err != nil {
	// 	log.Fatalf("Error creating Helm chart: %v", err)
	// }

	// fmt.Printf("Helm chart '%s' created successfully at: %s\n", helm.ChartName, chartPath)
}
