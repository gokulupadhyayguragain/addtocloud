package main

import (
	"crypto/tls"
	"fmt"
	"net/smtp"
	"time"
)

func main() {
	// Your REAL SMTP credentials
	host := "smtp.zoho.com"
	port := "587"
	username := "noreply@addtocloud.tech"
	password := "xcBP8i1URm7n"
	from := "noreply@addtocloud.tech"
	to := "admin@addtocloud.tech"

	// Test message
	subject := "AddToCloud SMTP Test - Real Email!"
	body := fmt.Sprintf(`
Hello!

This is a REAL email sent from your AddToCloud backend using:
- Zoho SMTP: %s:%s
- From: %s
- Time: %s

Your SMTP integration is working perfectly! ✅

Best regards,
AddToCloud System
`, host, port, from, time.Now().Format(time.RFC3339))

	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s",
		from, to, subject, body)

	// SMTP Auth
	auth := smtp.PlainAuth("", username, password, host)

	// TLS config
	tlsconfig := &tls.Config{
		InsecureSkipVerify: false,
		ServerName:         host,
	}

	// Connect to server with STARTTLS (not direct TLS)
	c, err := smtp.Dial(host + ":" + port)
	if err != nil {
		fmt.Printf("❌ Failed to connect to SMTP server: %v\n", err)
		return
	}
	defer c.Close()

	// Start TLS
	if err = c.StartTLS(tlsconfig); err != nil {
		fmt.Printf("❌ Failed to start TLS: %v\n", err)
		return
	}

	// Auth
	if err = c.Auth(auth); err != nil {
		fmt.Printf("❌ SMTP auth failed: %v\n", err)
		return
	}

	// Send email
	if err = c.Mail(from); err != nil {
		fmt.Printf("❌ Failed to set sender: %v\n", err)
		return
	}

	if err = c.Rcpt(to); err != nil {
		fmt.Printf("❌ Failed to set recipient: %v\n", err)
		return
	}

	w, err := c.Data()
	if err != nil {
		fmt.Printf("❌ Failed to get data writer: %v\n", err)
		return
	}
	defer w.Close()

	_, err = w.Write([]byte(msg))
	if err != nil {
		fmt.Printf("❌ Failed to write message: %v\n", err)
		return
	}

	fmt.Printf("✅ REAL EMAIL SENT SUCCESSFULLY!\n")
	fmt.Printf("📧 From: %s\n", from)
	fmt.Printf("📧 To: %s\n", to)
	fmt.Printf("📧 Via: %s:%s\n", host, port)
	fmt.Printf("🕐 Time: %s\n", time.Now().Format(time.RFC3339))
	fmt.Printf("\n🎉 Your SMTP credentials are REAL and WORKING!\n")
}
