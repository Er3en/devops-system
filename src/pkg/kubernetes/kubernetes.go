package kubernetes

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func ListPods() {
	// Load kubeconfig
	config, err := clientcmd.BuildConfigFromFlags("", ".kube/config")
	if err != nil {
		log.Fatal(err)
	}

	// Create a Kubernetes client
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatal(err)
	}

	// List pods in the default namespace
	pods, err := clientset.CoreV1().Pods("default").List(context.Background(), metav1.ListOptions{})
	if err != nil {
		log.Fatal(err)
	}

	// Print pod names
	for _, pod := range pods.Items {
		fmt.Println("Pod Name:", pod.Name)
	}
}

func Setup(kubectlConfigSecret string) {
	kubeDir := filepath.Join(os.Getenv("PWD"), ".kube")
	err := os.MkdirAll(kubeDir, 0755)
	if err != nil {
		log.Fatal("Errror creating ~/.kube directory")
	}
	kubeConfigPath := filepath.Join(kubeDir, "config")
	fmt.Println("Kubectl config path:", kubeConfigPath)
	err = os.WriteFile(kubeConfigPath, []byte(kubectlConfigSecret), 0644)
	if err != nil {
		log.Fatal("Error writing to kube config:", err)
	}
}
