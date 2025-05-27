```markdown
# 🚀 Linux AI Management System

A powerful web-based platform for managing Linux servers using natural language commands powered by AI. Transform complex server administration into simple conversational interactions.

## ✨ Features

### 🤖 AI-Powered Command Processing
- **Natural Language Interface**: Type commands in plain English like "check disk space" or "show memory usage"
- **Multiple AI Backends**: Support for OpenAI GPT-4 and local Ollama with Qwen models
- **Smart Command Translation**: Automatically converts natural language to safe Linux commands
- **Safety Filtering**: Built-in protection against dangerous operations

### 🖥️ Server Management
- **Multi-Server Dashboard**: Manage multiple Linux servers from a single interface
- **Real-time Status Monitoring**: Live server health, CPU, memory, and disk usage
- **Secure Agent Communication**: Python-based agents with JWT authentication
- **Command History**: Track all executed commands with timestamps and results

### 🔐 Security & Authentication
- **Role-Based Access Control**: Admin, User, and Viewer roles with different permissions
- **JWT Authentication**: Secure token-based authentication system
- **Command Filtering**: Whitelist-based command approval system
- **Audit Logging**: Complete command execution history

### 🎨 Modern Web Interface
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Real-time Updates**: Live command execution with progress indicators
- **Dark/Light Mode**: Customizable UI themes
- **Intuitive UX**: Clean, modern interface built with Next.js and Tailwind CSS

## 🏗️ Architecture

```

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Dashboard │    │   AI Processing │    │  Server Agents  │
│   (Next.js)     │◄──►│   (OpenAI/Qwen) │    │   (Python)      │
│                 │    │                 │    │                 │
│ • Authentication│    │ • NL to Linux   │    │ • Command Exec  │
│ • Server Mgmt   │    │ • Safety Check  │    │ • System Info   │
│ • Command UI    │    │ • Local/Cloud   │    │ • Health Check  │
└─────────────────┘    └─────────────────┘    └─────────────────┘

```plaintext

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ and npm
- Python 3.8+
- Linux servers for management
- OpenAI API key (optional, for enhanced AI features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/linux-ai-management.git
   cd linux-ai-management
```

2. **Install dependencies**

```shellscript
npm install
```


3. **Set up environment variables**

```shellscript
cp .env.example .env.local
# Add your OpenAI API key and other configuration
```


4. **Start the development server**

```shellscript
npm run dev
```


5. **Access the dashboard**

1. Open [http://localhost:3000](http://localhost:3000)
2. Login with: `admin` / `admin123`





### Server Agent Setup

1. **Install the agent on your Linux servers**

```shellscript
# Copy agent files to your server
scp -r server-agent/ user@your-server:/opt/

# Install and start the agent
ssh user@your-server
cd /opt/server-agent
./install_agent.sh
```


2. **Add servers to the dashboard**

1. Use the "Add Server" button in the web interface
2. Provide server details and credentials





## 📖 Usage Examples

### Natural Language Commands

- **"Check disk space"** → `df -h`
- **"Show memory usage"** → `free -h`
- **"List running processes"** → `ps aux`
- **"Check system uptime"** → `uptime`
- **"Show network connections"** → `netstat -tuln`


### Advanced Features

- **Multi-server execution**: Run commands across multiple servers
- **Command templates**: Save frequently used commands
- **Scheduled tasks**: Set up recurring maintenance tasks
- **Alert system**: Get notified of system issues


## 🛠️ Technology Stack

### Frontend

- **Next.js 14**: React framework with App Router
- **TypeScript**: Type-safe development
- **Tailwind CSS**: Utility-first CSS framework
- **Radix UI**: Accessible component primitives
- **Lucide Icons**: Beautiful icon library


### Backend

- **Next.js API Routes**: Serverless API endpoints
- **JWT Authentication**: Secure token-based auth
- **bcryptjs**: Password hashing
- **AI SDK**: Unified AI model integration


### AI Integration

- **OpenAI GPT-4**: Advanced natural language processing
- **Ollama**: Local AI model hosting
- **Qwen Models**: Open-source language models


### Server Agents

- **FastAPI**: High-performance Python web framework
- **psutil**: System monitoring and process management
- **asyncio**: Asynchronous command execution


## 🔧 Configuration

### Environment Variables

```plaintext
# Authentication
JWT_SECRET=your-jwt-secret
NEXTAUTH_SECRET=your-nextauth-secret

# AI Configuration
OPENAI_API_KEY=your-openai-api-key
OLLAMA_URL=http://localhost:11434

# Database (optional)
DATABASE_URL=your-database-url
```

### Server Agent Configuration

```python
# Safe commands whitelist
SAFE_COMMANDS = [
    "df", "free", "ps", "top", "uptime", 
    "whoami", "id", "uname", "netstat"
]

# Security settings
COMMAND_TIMEOUT = 30
MAX_OUTPUT_SIZE = 1024 * 1024  # 1MB
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Commit your changes: `git commit -m 'Add amazing feature'`
5. Push to the branch: `git push origin feature/amazing-feature`
6. Open a Pull Request


## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenAI](https://openai.com/) for GPT models
- [Ollama](https://ollama.ai/) for local AI hosting
- [Vercel](https://vercel.com/) for Next.js framework
- [Alibaba Cloud](https://www.alibabacloud.com/) for Qwen models


## 🗺️ Roadmap

- **Multi-cloud support** (AWS, GCP, Azure)
- **Container management** (Docker, Kubernetes)
- **Advanced monitoring** (Grafana integration)
- **Mobile app** (React Native)
- **Plugin system** (Custom command extensions)
- **Team collaboration** (Shared workspaces)


---

⭐ **Star this repository if you find it helpful!**

Made with ❤️ by Sunil Kumar

```plaintext

## 📋 Additional Files to Include

You should also create these additional files for a complete GitHub repository:

### `.env.example`
```env
# Copy this file to .env.local and fill in your values

# Authentication
JWT_SECRET=your-jwt-secret-here
NEXTAUTH_SECRET=your-nextauth-secret-here

# AI Configuration
OPENAI_API_KEY=your-openai-api-key-here
OLLAMA_URL=http://localhost:11434

# Environment
NODE_ENV=development
```

### `CONTRIBUTING.md`

```markdown
# Contributing to Linux AI Management System

Thank you for your interest in contributing! Please read these guidelines before submitting your contribution.

## Development Process
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Code Style
- Use TypeScript for all new code
- Follow the existing code formatting
- Add JSDoc comments for functions
- Use meaningful variable names

## Testing
- Add unit tests for new features
- Ensure all tests pass before submitting
- Test on multiple browsers if UI changes

## Reporting Issues
- Use the GitHub issue tracker
- Provide detailed reproduction steps
- Include system information
```
