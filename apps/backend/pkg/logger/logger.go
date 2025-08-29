package logger

import (
	"os"

	"github.com/sirupsen/logrus"
)

var Log *logrus.Logger

// Init initializes the logger
func Init() {
	Log = logrus.New()

	// Set log level based on environment
	env := os.Getenv("ENV")
	switch env {
	case "production":
		Log.SetLevel(logrus.InfoLevel)
		Log.SetFormatter(&logrus.JSONFormatter{})
	case "development":
		Log.SetLevel(logrus.DebugLevel)
		Log.SetFormatter(&logrus.TextFormatter{
			FullTimestamp: true,
			ForceColors:   true,
		})
	default:
		Log.SetLevel(logrus.InfoLevel)
		Log.SetFormatter(&logrus.TextFormatter{
			FullTimestamp: true,
		})
	}

	Log.SetOutput(os.Stdout)
	Log.Info("Logger initialized")
}

// GetLogger returns the global logger instance
func GetLogger() *logrus.Logger {
	if Log == nil {
		Init()
	}
	return Log
}
