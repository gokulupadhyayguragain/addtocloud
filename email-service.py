import smtplib
import json
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
import os
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Zoho SMTP Configuration
ZOHO_CONFIG = {
    'host': 'smtp.zoho.com',
    'port': 587,
    'user': 'noreply@addtocloud.tech',
    'password': 'xcBP8i1URm7n',  # App password from user
    'admin_email': 'admin@addtocloud.tech'
}

class ZohoEmailService:
    def __init__(self):
        self.smtp_host = ZOHO_CONFIG['host']
        self.smtp_port = ZOHO_CONFIG['port']
        self.username = ZOHO_CONFIG['user']
        self.password = ZOHO_CONFIG['password']
        self.admin_email = ZOHO_CONFIG['admin_email']
    
    def send_contact_notification(self, contact_data):
        """Send contact form notification email"""
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['Subject'] = f"New Contact Form Submission from {contact_data['name']}"
            msg['From'] = self.username
            msg['To'] = self.admin_email
            
            # Create HTML content
            html_content = f"""
            <html>
            <head></head>
            <body>
                <h2 style="color: #2563eb;">New Contact Form Submission</h2>
                <div style="background-color: #f8fafc; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <p><strong>Name:</strong> {contact_data['name']}</p>
                    <p><strong>Email:</strong> {contact_data['email']}</p>
                    <p><strong>Service:</strong> {contact_data.get('service', 'Not specified')}</p>
                    <p><strong>Submitted:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} UTC</p>
                </div>
                <div style="background-color: #fff; padding: 20px; border-left: 4px solid #2563eb; margin: 20px 0;">
                    <h3>Message:</h3>
                    <p style="line-height: 1.6;">{contact_data['message']}</p>
                </div>
                <hr style="margin: 30px 0;">
                <p style="color: #64748b; font-size: 14px;">
                    <em>This email was sent automatically from the AddToCloud.tech contact form.</em><br>
                    <em>Reply directly to this email to respond to {contact_data['name']} at {contact_data['email']}</em>
                </p>
            </body>
            </html>
            """
            
            # Attach HTML content
            html_part = MIMEText(html_content, 'html')
            msg.attach(html_part)
            
            # Connect to server and send email
            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                server.starttls()
                server.login(self.username, self.password)
                server.send_message(msg)
            
            logger.info(f"Contact form email sent successfully to {self.admin_email}")
            return {'success': True, 'message': 'Email sent successfully'}
            
        except Exception as e:
            logger.error(f"Failed to send contact form email: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def send_welcome_email(self, user_email, user_name):
        """Send welcome email to new users"""
        try:
            msg = MIMEMultipart('alternative')
            msg['Subject'] = "Welcome to AddToCloud.tech!"
            msg['From'] = self.username
            msg['To'] = user_email
            
            html_content = f"""
            <html>
            <head></head>
            <body>
                <div style="max-width: 600px; margin: 0 auto; font-family: Arial, sans-serif;">
                    <h1 style="color: #2563eb; text-align: center;">Welcome to AddToCloud.tech!</h1>
                    <div style="background-color: #f8fafc; padding: 30px; border-radius: 12px; margin: 20px 0;">
                        <h2 style="color: #1e40af;">Hello {user_name}!</h2>
                        <p style="line-height: 1.6; color: #374151;">
                            Thank you for joining AddToCloud.tech! We're excited to help you with your cloud journey.
                        </p>
                        <p style="line-height: 1.6; color: #374151;">
                            Our platform provides multi-cloud solutions to help you:
                        </p>
                        <ul style="color: #374151; line-height: 1.8;">
                            <li>Deploy applications across AWS, Azure, and GCP</li>
                            <li>Monitor your cloud infrastructure</li>
                            <li>Optimize costs and performance</li>
                            <li>Ensure security and compliance</li>
                        </ul>
                        <div style="text-align: center; margin: 30px 0;">
                            <a href="https://addtocloud.tech/dashboard" 
                               style="background-color: #2563eb; color: white; padding: 12px 24px; 
                                      text-decoration: none; border-radius: 6px; display: inline-block;">
                                Get Started
                            </a>
                        </div>
                    </div>
                    <p style="color: #64748b; font-size: 14px; text-align: center;">
                        If you have any questions, feel free to reach out to us at admin@addtocloud.tech
                    </p>
                </div>
            </body>
            </html>
            """
            
            html_part = MIMEText(html_content, 'html')
            msg.attach(html_part)
            
            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                server.starttls()
                server.login(self.username, self.password)
                server.send_message(msg)
            
            logger.info(f"Welcome email sent successfully to {user_email}")
            return {'success': True, 'message': 'Welcome email sent'}
            
        except Exception as e:
            logger.error(f"Failed to send welcome email: {str(e)}")
            return {'success': False, 'error': str(e)}

# Initialize email service
email_service = ZohoEmailService()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'AddToCloud Email Service',
        'version': '1.0.0',
        'smtp_configured': True,
        'zoho_host': ZOHO_CONFIG['host']
    })

@app.route('/send/contact', methods=['POST'])
def send_contact_email():
    """Send contact form notification email"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'email', 'message']
        for field in required_fields:
            if not data.get(field):
                return jsonify({
                    'success': False,
                    'error': f'Missing required field: {field}'
                }), 400
        
        # Send email
        result = email_service.send_contact_notification(data)
        
        if result['success']:
            return jsonify({
                'success': True,
                'message': 'Contact form email sent successfully',
                'timestamp': datetime.now().isoformat()
            })
        else:
            return jsonify({
                'success': False,
                'error': result['error']
            }), 500
            
    except Exception as e:
        logger.error(f"Error in send_contact_email: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@app.route('/send/welcome', methods=['POST'])
def send_welcome_email():
    """Send welcome email to new users"""
    try:
        data = request.get_json()
        
        if not data.get('email') or not data.get('name'):
            return jsonify({
                'success': False,
                'error': 'Missing required fields: email, name'
            }), 400
        
        result = email_service.send_welcome_email(data['email'], data['name'])
        
        if result['success']:
            return jsonify({
                'success': True,
                'message': 'Welcome email sent successfully',
                'timestamp': datetime.now().isoformat()
            })
        else:
            return jsonify({
                'success': False,
                'error': result['error']
            }), 500
            
    except Exception as e:
        logger.error(f"Error in send_welcome_email: {str(e)}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@app.route('/test/smtp', methods=['GET'])
def test_smtp_connection():
    """Test SMTP connection to Zoho"""
    try:
        with smtplib.SMTP(ZOHO_CONFIG['host'], ZOHO_CONFIG['port']) as server:
            server.starttls()
            server.login(ZOHO_CONFIG['user'], ZOHO_CONFIG['password'])
        
        return jsonify({
            'success': True,
            'message': 'SMTP connection successful',
            'host': ZOHO_CONFIG['host'],
            'port': ZOHO_CONFIG['port'],
            'user': ZOHO_CONFIG['user']
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'message': 'SMTP connection failed'
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
