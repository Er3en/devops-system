package main

import (
	"context"
	"fmt"
	"log"

	"path/filepath"

	helm "helm.sh/helm/v3/pkg/action"
	helmclient "helm.sh/helm/v3/pkg/cli"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
)

// Dry-run a Helm installation
func dryRunHelmInstall(chartPath, releaseName, kubeConfig string) {
	// Initialize Helm configuration
	helmSettings := helmclient.New()
	helmSettings.KubeConfig = kubeConfig

	// Initialize Helm action configuration
	actionConfig := new(helm.ActionConfiguration)
	client := helm.NewInstall(actionConfig)
	client.DryRun = true
	client.ReleaseName = releaseName
	client.ChartPath = chartPath

	// Perform the dry-run
	_, err := client.Run()
	if err != nil {
		log.Fatalf("Error during Helm dry-run: %v", err)
	} else {
		fmt.Println("Helm dry-run successful!")
	}
}

// Dry-run a Kubernetes deployment
func validateDeployment(clientset *kubernetes.Clientset) {
	// Define a simple Kubernetes Deployment (example)
	deployment := &metav1.ObjectMeta{
		Name:      "nginx-deployment",
		Namespace: "default",
	}

	// Perform dry-run
	_, err := clientset.AppsV1().Deployments("default").Create(context.Background(), deployment, metav1.CreateOptions{
		DryRun: []string{metav1.DryRunAll},
	})
	if err != nil {
		log.Fatalf("Error during Kubernetes dry-run: %v", err)
	} else {
		fmt.Println("Kubernetes dry-run successful!")
	}
}

func main() {
	// Initialize Helm and Kubernetes configurations
	kubeConfig := "/path/to/your/kubeconfig" // Update the path if needed

	// Example chart path and release name for Helm dry-run
	chartPath := "/path/to/your/chart" // Update with the correct chart path
	releaseName := "nginx-release"

	// Run Helm dry-run
	dryRunHelmInstall(chartPath, releaseName, kubeConfig)

	// Initialize Kubernetes Client
	kubeconfig := filepath.Join(homedir.HomeDir(), ".kube", "config")
	if kubeConfig != "" {
		kubeconfig = kubeConfig
	}

	// Create a new kubeconfig and clientset
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		log.Fatalf("Error creating kubeconfig: %v", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatalf("Error creating Kubernetes client: %v", err)
	}

	// Run Kubernetes dry-run validation
	validateDeployment(clientset)
}
