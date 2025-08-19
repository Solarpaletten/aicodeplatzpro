import React from 'react';
import { Plus, Code, Users, TrendingUp } from 'lucide-react';

const Dashboard: React.FC = () => {
  return (
    <div className="p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">
            Welcome to AI IT Solar
          </h1>
          <p className="text-gray-400">
            AI-powered code review and analysis platform
          </p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="glass-effect rounded-xl p-6">
            <div className="flex items-center">
              <Code className="h-8 w-8 text-solar-400" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-400">Total Reviews</p>
                <p className="text-2xl font-semibold text-white">1,234</p>
              </div>
            </div>
          </div>
          
          <div className="glass-effect rounded-xl p-6">
            <div className="flex items-center">
              <Users className="h-8 w-8 text-green-400" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-400">Team Members</p>
                <p className="text-2xl font-semibold text-white">12</p>
              </div>
            </div>
          </div>
          
          <div className="glass-effect rounded-xl p-6">
            <div className="flex items-center">
              <TrendingUp className="h-8 w-8 text-orange-400" />
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-400">Time Saved</p>
                <p className="text-2xl font-semibold text-white">45h</p>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="glass-effect rounded-xl p-6">
          <h2 className="text-xl font-semibold text-white mb-4">Quick Actions</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <button className="btn-primary flex items-center justify-center space-x-2 py-4">
              <Plus className="h-5 w-5" />
              <span>New Code Review</span>
            </button>
            
            <button className="glass-effect border border-white/20 text-white font-semibold py-4 px-4 rounded-lg hover:bg-white/5 transition-all duration-200 flex items-center justify-center space-x-2">
              <Code className="h-5 w-5" />
              <span>Compare Files</span>
            </button>
            
            <button className="glass-effect border border-white/20 text-white font-semibold py-4 px-4 rounded-lg hover:bg-white/5 transition-all duration-200 flex items-center justify-center space-x-2">
              <Users className="h-5 w-5" />
              <span>Invite Team</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
