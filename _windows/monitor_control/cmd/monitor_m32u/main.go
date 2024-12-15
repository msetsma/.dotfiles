package main

import (
	"log"

	"github.com/msetsma/cmm_executor"
)

const (
	MonitorID       = "GBT3204"
	VPCCode         = "60"
	DisplayPortCode = "15"
	HDMI1Code       = "17"
	USBC            = "16"
)

func main() {
	// build executor
	executor, err := cmm_executor.ControlMyMonitor("ControlMyMonitor.exe")
	if err != nil {
		log.Fatalf("failed to create executor: %s", err)
	}
	// switch between ports.
	executor.SwitchValue(MonitorID, VPCCode, []string{DisplayPortCode, USBC})
}
