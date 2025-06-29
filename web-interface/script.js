class EVChargingChatbot {
    constructor() {
        this.chatWidget = document.getElementById('chatWidget');
        this.chatToggle = document.getElementById('chatToggle');
        this.chatMessages = document.getElementById('chatMessages');
        this.messageInput = document.getElementById('messageInput');
        this.sendBtn = document.getElementById('sendBtn');
        this.typingIndicator = document.getElementById('typingIndicator');
        this.notificationBadge = document.getElementById('notificationBadge');
        
        this.userId = 'web_user_' + Date.now();
        this.selectedLanguage = null;
        this.isTyping = false;
        
        this.initializeEventListeners();
        this.setupAutoScroll();
    }
    
    initializeEventListeners() {
        // Toggle chat widget
        this.chatToggle.addEventListener('click', () => this.toggleChat());
        
        // Close/minimize buttons
        document.getElementById('closeBtn').addEventListener('click', () => this.closeChat());
        document.getElementById('minimizeBtn').addEventListener('click', () => this.minimizeChat());
        
        // Send message
        this.sendBtn.addEventListener('click', () => this.sendMessage());
        this.messageInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.sendMessage();
        });
        
        // Language selection
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('lang-btn')) {
                this.selectLanguage(e.target.dataset.lang);
            }
        });
        
        // Quick replies
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('quick-reply-btn')) {
                this.sendQuickReply(e.target.dataset.message);
            }
        });
        
        // Input events
        this.messageInput.addEventListener('input', () => {
            this.sendBtn.disabled = !this.messageInput.value.trim();
        });
    }
    
    toggleChat() {
        const isVisible = this.chatWidget.style.display === 'flex';
        
        if (isVisible) {
            this.closeChat();
        } else {
            this.openChat();
        }
    }
    
    openChat() {
        this.chatWidget.style.display = 'flex';
        this.chatToggle.style.display = 'none';
        this.notificationBadge.style.display = 'none';
        this.messageInput.focus();
        this.scrollToBottom();
    }
    
    closeChat() {
        this.chatWidget.style.display = 'none';
        this.chatToggle.style.display = 'flex';
    }
    
    minimizeChat() {
        this.closeChat();
    }
    
    async selectLanguage(language) {
        this.selectedLanguage = language;
        
        // Add user message
        this.addMessage(`Selected: ${language}`, 'user');
        
        // Send to Rasa
        await this.sendToRasa(`/select_language{"language": "${language}"}`);
    }
    
    async sendMessage() {
        const message = this.messageInput.value.trim();
        if (!message) return;
        
        // Add user message to chat
        this.addMessage(message, 'user');
        this.messageInput.value = '';
        this.sendBtn.disabled = true;
        
        // Send to Rasa
        await this.sendToRasa(message);
    }
    
    async sendQuickReply(message) {
        this.addMessage(message, 'user');
        await this.sendToRasa(message);
    }
    
    async sendToRasa(message) {
        this.showTyping();
        
        try {
            const response = await fetch('http://localhost:5005/webhooks/rest/webhook', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    sender: this.userId,
                    message: message
                })
            });
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const data = await response.json();
            this.hideTyping();
            
            // Process Rasa responses
            if (data && data.length > 0) {
                for (const botMessage of data) {
                    this.addBotMessage(botMessage);
                }
            } else {
                this.addMessage("I'm having trouble connecting right now. Please try again in a moment.", 'bot');
            }
            
        } catch (error) {
            console.error('Error sending message to Rasa:', error);
            this.hideTyping();
            this.addMessage("I'm currently offline. Please try again later or contact our team directly.", 'bot');
        }
    }
    
    addMessage(text, sender) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${sender}-message`;
        
        const avatar = document.createElement('div');
        avatar.className = 'message-avatar';
        avatar.innerHTML = sender === 'bot' ? '<i class="fas fa-robot"></i>' : '<i class="fas fa-user"></i>';
        
        const content = document.createElement('div');
        content.className = 'message-content';
        content.innerHTML = this.formatMessage(text);
        
        messageDiv.appendChild(avatar);
        messageDiv.appendChild(content);
        
        this.chatMessages.appendChild(messageDiv);
        this.scrollToBottom();
    }
    
    addBotMessage(botMessage) {
        const messageDiv = document.createElement('div');
        messageDiv.className = 'message bot-message';
        
        const avatar = document.createElement('div');
        avatar.className = 'message-avatar';
        avatar.innerHTML = '<i class="fas fa-robot"></i>';
        
        const content = document.createElement('div');
        content.className = 'message-content';
        
        // Handle text message
        if (botMessage.text) {
            content.innerHTML = this.formatMessage(botMessage.text);
        }
        
        // Handle buttons
        if (botMessage.buttons) {
            const buttonsContainer = document.createElement('div');
            buttonsContainer.className = 'language-buttons';
            
            botMessage.buttons.forEach(button => {
                const buttonElement = document.createElement('button');
                buttonElement.className = 'lang-btn';
                buttonElement.textContent = button.title;
                buttonElement.onclick = () => this.sendToRasa(button.payload);
                buttonsContainer.appendChild(buttonElement);
            });
            
            content.appendChild(buttonsContainer);
        }
        
        // Handle quick replies
        if (botMessage.quick_replies) {
            const quickRepliesContainer = document.createElement('div');
            quickRepliesContainer.className = 'quick-replies';
            
            botMessage.quick_replies.forEach(reply => {
                const replyElement = document.createElement('button');
                replyElement.className = 'quick-reply-btn';
                replyElement.textContent = reply.title;
                replyElement.onclick = () => this.sendToRasa(reply.payload);
                quickRepliesContainer.appendChild(replyElement);
            });
            
            content.appendChild(quickRepliesContainer);
        }
        
        messageDiv.appendChild(avatar);
        messageDiv.appendChild(content);
        
        this.chatMessages.appendChild(messageDiv);
        this.scrollToBottom();
    }
    
    formatMessage(text) {
        // Convert markdown-style formatting to HTML
        return text
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/g, '<em>$1</em>')
            .replace(/\n/g, '<br>')
            .replace(/🔌|⚡|🚗|🏠|🏢|💰|🌍|🇺🇸|🇫🇷|🇸🇦|🇲🇦/g, '<span style="font-size: 1.2em;">$&</span>');
    }
    
    showTyping() {
        this.isTyping = true;
        this.typingIndicator.style.display = 'flex';
        this.scrollToBottom();
    }
    
    hideTyping() {
        this.isTyping = false;
        this.typingIndicator.style.display = 'none';
    }
    
    scrollToBottom() {
        setTimeout(() => {
            this.chatMessages.scrollTop = this.chatMessages.scrollHeight;
        }, 100);
    }
    
    setupAutoScroll() {
        // Auto-scroll when new messages are added
        const observer = new MutationObserver(() => {
            if (!this.isTyping) {
                this.scrollToBottom();
            }
        });
        
        observer.observe(this.chatMessages, {
            childList: true,
            subtree: true
        });
    }
}

// Initialize the chatbot when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new EVChargingChatbot();
});

// Add some demo functionality for the main website
document.addEventListener('DOMContentLoaded', () => {
    // Smooth scrolling for navigation links
    document.querySelectorAll('nav a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
    
    // Auto-open chat after a delay (demo purposes)
    setTimeout(() => {
        const notificationBadge = document.getElementById('notificationBadge');
        if (notificationBadge) {
            notificationBadge.style.display = 'block';
        }
    }, 3000);
});