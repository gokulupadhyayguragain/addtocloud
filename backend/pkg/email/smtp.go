package email

import (
	"crypto/tls"
	"fmt"
	"net/smtp"
	"os"
	"time"
)

type SMTPConfig struct {
	Host     string
	Port     string
	Username string
	Password string
	From     string
}

func NewSMTPConfig() *SMTPConfig {
	return &SMTPConfig{
		Host:     os.Getenv("SMTP_HOST"),
		Port:     os.Getenv("SMTP_PORT"),
		Username: os.Getenv("SMTP_USERNAME"),
		Password: os.Getenv("SMTP_PASSWORD"),
		From:     os.Getenv("SMTP_FROM"),
	}
}

func (s *SMTPConfig) SendContactEmail(name, email, message string) error {
	if s.Host == "" || s.Username == "" || s.Password == "" {
		return fmt.Errorf("SMTP not configured")
	}

	subject := fmt.Sprintf("New Contact Form Message from %s", name)
	body := fmt.Sprintf(`
New contact form submission received:

Name: %s
Email: %s
Submitted: %s

Message:
%s

---
Sent from AddToCloud Contact Form
	`, name, email, time.Now().Format(time.RFC3339), message)

	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s",
		s.From, "admin@addtocloud.tech", subject, body)

	return s.sendEmail("admin@addtocloud.tech", []byte(msg))
}

func (s *SMTPConfig) SendAutoReply(email, name string) error {
	if s.Host == "" || s.Username == "" || s.Password == "" {
		return fmt.Errorf("SMTP not configured")
	}

	subject := "Thank you for contacting AddToCloud"
	body := fmt.Sprintf(`
Hi %s,

Thank you for reaching out to AddToCloud! We've received your message and will get back to you within 24 hours.

In the meantime, feel free to explore our platform:
- Dashboard: https://dashboard.addtocloud.tech
- Documentation: https://docs.addtocloud.tech
- Status Page: https://status.addtocloud.tech

Best regards,
The AddToCloud Team

---
This is an automated response. Please do not reply to this email.
	`, name)

	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s",
		s.From, email, subject, body)

	return s.sendEmail(email, []byte(msg))
}

func (s *SMTPConfig) SendAccessRequestNotification(requestID, name, email, company string) error {
	if s.Host == "" || s.Username == "" || s.Password == "" {
		return fmt.Errorf("SMTP not configured")
	}

	subject := fmt.Sprintf("New Access Request: %s from %s", requestID, company)
	body := fmt.Sprintf(`
New access request received:

Request ID: %s
Name: %s
Email: %s
Company: %s
Submitted: %s

Review at: https://admin.addtocloud.tech/access-requests/%s

---
AddToCloud Admin Notification
	`, requestID, name, email, company, time.Now().Format(time.RFC3339), requestID)

	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s",
		s.From, "admin@addtocloud.tech", subject, body)

	return s.sendEmail("admin@addtocloud.tech", []byte(msg))
}

func (s *SMTPConfig) sendEmail(to string, message []byte) error {
	// Connect to server
	conn, err := smtp.Dial(s.Host + ":" + s.Port)
	if err != nil {
		return fmt.Errorf("failed to connect to SMTP server: %v", err)
	}
	defer conn.Close()

	// Start TLS
	if err = conn.StartTLS(&tls.Config{
		ServerName: s.Host,
		MinVersion: tls.VersionTLS12,
	}); err != nil {
		return fmt.Errorf("failed to start TLS: %v", err)
	}

	// Authenticate
	auth := smtp.PlainAuth("", s.Username, s.Password, s.Host)
	if err = conn.Auth(auth); err != nil {
		return fmt.Errorf("authentication failed: %v", err)
	}

	// Set sender
	if err = conn.Mail(s.From); err != nil {
		return fmt.Errorf("failed to set sender: %v", err)
	}

	// Set recipient
	if err = conn.Rcpt(to); err != nil {
		return fmt.Errorf("failed to set recipient: %v", err)
	}

	// Send message
	w, err := conn.Data()
	if err != nil {
		return fmt.Errorf("failed to get data writer: %v", err)
	}

	if _, err = w.Write(message); err != nil {
		return fmt.Errorf("failed to write message: %v", err)
	}

	if err = w.Close(); err != nil {
		return fmt.Errorf("failed to close data writer: %v", err)
	}

	return nil
}

func (s *SMTPConfig) TestConnection() error {
	if s.Host == "" || s.Username == "" || s.Password == "" {
		return fmt.Errorf("SMTP configuration incomplete")
	}

	// Test basic connectivity
	conn, err := smtp.Dial(s.Host + ":" + s.Port)
	if err != nil {
		return fmt.Errorf("failed to connect: %v", err)
	}
	defer conn.Close()

	// Test TLS
	if err = conn.StartTLS(&tls.Config{
		ServerName: s.Host,
		MinVersion: tls.VersionTLS12,
	}); err != nil {
		return fmt.Errorf("TLS failed: %v", err)
	}

	// Test authentication
	auth := smtp.PlainAuth("", s.Username, s.Password, s.Host)
	if err = conn.Auth(auth); err != nil {
		return fmt.Errorf("authentication failed: %v", err)
	}

	return nil
}

func (s *SMTPConfig) SendTestEmail(to string) error {
	subject := "AddToCloud API - SMTP Test"
	body := fmt.Sprintf(`
This is a test email from the AddToCloud API.

Sent at: %s
From: %s
To: %s

If you receive this email, SMTP is working correctly!

---
AddToCloud Enterprise Platform
	`, time.Now().Format(time.RFC3339), s.From, to)

	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s",
		s.From, to, subject, body)

	return s.sendEmail(to, []byte(msg))
}

func (s *SMTPConfig) IsConfigured() bool {
	return s.Host != "" && s.Username != "" && s.Password != "" && s.From != ""
}
