// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"encoding/xml"
	"fmt"
	"io"
	"os"
)

// Define XML structures
type TestSuites struct {
	TestSuites []TestSuite `xml:"testsuite"`
}

type TestSuite struct {
	Name      string     `xml:"name,attr"`
	Failures  int        `xml:"failures,attr"` // Captures failure count
	TestCases []TestCase `xml:"testcase"`
}

type TestCase struct {
	ClassName string   `xml:"classname,attr"`
	Name      string   `xml:"name,attr"`
	Time      string   `xml:"time,attr"`
	Failure   *Failure `xml:"failure"`
	Error     *Failure `xml:"error"`
}

type Failure struct {
	Message string `xml:",chardata"`
}

func main() {
	xmlFile := "report.xml"

	// Read the XML file
	file, err := os.Open(xmlFile)
	if err != nil {
		fmt.Println("Error opening XML file:", err)
		return
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		fmt.Println("Error reading XML file:", err)
		return
	}

	// Parse XML
	var testSuites TestSuites
	err = xml.Unmarshal(data, &testSuites)
	if err != nil {
		fmt.Println("Error parsing XML:", err)
		return
	}

	// Check if there are any failures
	totalFailures := 0
	fmt.Println("Test Results:")

	for _, suite := range testSuites.TestSuites {
		fmt.Printf("Suite: %s | Failures: %d\n", suite.Name, suite.Failures)
		totalFailures += suite.Failures
	}

	// If no failures, report success
	if totalFailures == 0 {
		fmt.Println("All tests passed successfully!")
	} else {
		// Send a non-zero exit code
		os.Exit(1)
	}
}
