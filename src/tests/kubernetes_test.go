package kubernetes

import (
	"strings"
	"testing"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/fake"
)

func TestCaptureOutput(t *testing.T) {
	tests := []struct {
		name     string
		input    func()
		expected string
	}{
		{
			name: "prints hello world",
			input: func() {
				println("Hello World")
			},
			expected: "Hello World\n",
		},
		{
			name: "empty output",
			input: func() {
			},
			expected: "",
		},
		{
			name: "multiple lines",
			input: func() {
				println("Line 1")
				println("Line 2")
			},
			expected: "Line 1\nLine 2\n",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			output := captureOutput(tt.input)
			if output != tt.expected {
				t.Errorf("captureOutput() = %v, want %v", output, tt.expected)
			}
		})
	}
}

// Helper function to create a fake k8s client for testing
func createFakeClient() kubernetes.Interface {
	return fake.NewSimpleClientset()
}

// Test helper function to verify captured output contains expected string
func assertOutputContains(t *testing.T, output string, expected string) {
	if !strings.Contains(output, expected) {
		t.Errorf("Expected output to contain %q, got %q", expected, output)
	}
}
