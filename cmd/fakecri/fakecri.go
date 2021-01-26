package main

import (
	"flag"
	"fmt"
	"os"
	"time"

	"k8s.io/klog"
	"k8s.io/kubernetes/pkg/kubelet/cri/remote"
	fakeremote "k8s.io/kubernetes/pkg/kubelet/cri/remote/fake"
)

var (
	BuildVersion   = "N/A"
	BuildTime      = "N/A"
	remoteEndpoint = flag.String("remote-endpoint", "unix:///tmp/fakecri.sock", "The endpoint to start listening on")
	version        = flag.Bool("version", false, "Show version")
)

func main() {
	flag.Parse()

	if *version {
		fmt.Printf("%s version %s built on %s\n", os.Args[0], BuildVersion, BuildTime)
		os.Exit(0)
	}

	fakeRemoteRuntime := fakeremote.NewFakeRemoteRuntime()
	if err := fakeRemoteRuntime.Start(*remoteEndpoint); err != nil {
		klog.Fatalf("Failed to start fake runtime %v.", err)
	}
	defer fakeRemoteRuntime.Stop()
	runtimeService, err := remote.NewRemoteRuntimeService(*remoteEndpoint, 15*time.Second)
	if err != nil {
		klog.Fatalf("Failed to init runtime service %v.", err)
	}
	runtimeInfo, err := runtimeService.Status()
	klog.Infof("%v %v", runtimeInfo, err)

	remoteImageService, err := remote.NewRemoteImageService(*remoteEndpoint, 15*time.Second)
	if err != nil {
		klog.Fatalf("Failed to init image service %v.", err)
	}
	imageServiceInfo, err := remoteImageService.ImageFsInfo()
	klog.Infof("%v %v", imageServiceInfo, err)

	time.Sleep(10 * time.Second)
}
