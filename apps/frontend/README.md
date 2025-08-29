# AddToCloud Frontend

Modern React/Next.js frontend for the AddToCloud enterprise platform.

## Features

- 🚀 Next.js 14 with App Router
- ⚡ React 18 with latest features
- 🎨 Tailwind CSS for styling
- 🌐 Three.js for 3D visualizations
- 📱 Responsive design
- 🧪 Jest & React Testing Library
- 💅 Prettier code formatting
- 📝 TypeScript support
- 🔧 Modern development tools

## Getting Started

### Prerequisites

- Node.js 18 or higher
- npm 8 or higher

### Installation

1. Install dependencies:
```bash
npm install
```

2. Copy environment variables:
```bash
cp .env.example .env.local
```

3. Start development server:
```bash
npm run dev
```

4. Open http://localhost:3000 in your browser

### Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run test` - Run tests
- `npm run test:watch` - Run tests in watch mode
- `npm run test:coverage` - Generate coverage report
- `npm run type-check` - Run TypeScript checks

## Project Structure

```
frontend/
├── components/          # React components
│   ├── ui/             # Reusable UI components
│   ├── layout/         # Layout components
│   ├── dashboard/      # Dashboard specific components
│   └── 3d/            # Three.js components
├── pages/              # Next.js pages
├── hooks/              # Custom React hooks
├── lib/                # Utility libraries
├── utils/              # Helper functions
├── types/              # TypeScript definitions
├── styles/             # Global styles
└── public/             # Static assets
```

## Technologies

- **Framework**: Next.js 14
- **UI Library**: React 18
- **Styling**: Tailwind CSS
- **3D Graphics**: Three.js
- **Animation**: Framer Motion
- **State Management**: Zustand
- **HTTP Client**: Axios
- **Forms**: React Hook Form + Zod
- **Testing**: Jest + React Testing Library
- **Icons**: Lucide React

## Development Guidelines

- Use TypeScript for type safety
- Follow React best practices
- Write tests for components
- Use Prettier for code formatting
- Follow component naming conventions
- Use custom hooks for reusable logic

## Environment Variables

See `.env.example` for required environment variables.

## Deployment

The application is configured for deployment with:
- Docker containers
- Kubernetes manifests
- CI/CD pipelines
- Multi-cloud support (AWS, Azure, GCP)
