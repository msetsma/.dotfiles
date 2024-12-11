# Default goal set to build all binaries.
.DEFAULT_GOAL := build

# Marking targets as phony to ensure they're always executed, even if a file with the same name exists.
.PHONY: fmt vet build build_monitor_hp42 build_monitorm32u clean

# Output binaries variables.
MONITOR_HP42_EXE := build/monitor_hp42.exe
MONITORM32U_EXE := build/monitor_m32u.exe

fmt:
	go fmt ./...

vet: fmt
	go vet ./...

build: vet build_monitor_hp42 build_monitorm32u

build_monitor_hp42:
	go build -o $(MONITOR_HP42_EXE) ./cmd/monitor_hp42

build_monitorm32u:
	go build -o $(MONITORM32U_EXE) ./cmd/monitor_m32u

clean:
	rm -f build/*.exe
