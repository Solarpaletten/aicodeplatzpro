import React from 'react';
import { Code2, Settings, Home, GitBranch } from 'lucide-react';
import { Link, useLocation } from 'react-router-dom';

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  const location = useLocation();

  const navigation = [
    { name: 'Dashboard', href: '/', icon: Home },
    { name: 'Reviews', href: '/reviews', icon: GitBranch },
    { name: 'Settings', href: '/settings', icon: Settings },
  ];

  return (
    <div className="flex h-screen">
      {/* Sidebar */}
      <div className="w-64 glass-effect border-r border-white/10">
        <div className="p-6">
          <div className="flex items-center space-x-2">
            <Code2 className="h-8 w-8 text-solar-400" />
            <h1 className="text-xl font-bold bg-gradient-to-r from-solar-400 to-solar-500 bg-clip-text text-transparent">
              AI IT Solar
            </h1>
          </div>
        </div>
        
        <nav className="px-4 space-y-2">
          {navigation.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.href;
            
            return (
              <Link
                key={item.name}
                to={item.href}
                className={`flex items-center space-x-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-solar-500/20 text-solar-400 border border-solar-500/30'
                    : 'text-gray-300 hover:bg-white/5 hover:text-white'
                }`}
              >
                <Icon className="h-5 w-5" />
                <span>{item.name}</span>
              </Link>
            );
          })}
        </nav>
      </div>

      {/* Main content */}
      <div className="flex-1 overflow-hidden">
        <main className="h-full overflow-y-auto">
          {children}
        </main>
      </div>
    </div>
  );
};

export default Layout;
