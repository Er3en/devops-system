package main

import (
	"fmt"
	"os/exec"
)

func runShellScript() {
	cmd := exec.Command("bash", "scripts/deploy.sh") // Path to your script
	output, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("Error running script:", err)
		return
	}
	fmt.Println("Script output:", string(output))
}

func main() {
	runShellScript()
}
