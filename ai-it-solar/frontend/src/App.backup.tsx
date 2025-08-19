import React, { useState } from 'react'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div className="App">
      <div className="container mx-auto p-8">
        <h1 className="text-4xl font-bold text-center mb-8">
          🚀 AI IT Solar PRO
        </h1>
        <div className="text-center">
          <button 
            className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
            onClick={() => setCount(count + 1)}
          >
            Count: {count}
          </button>
        </div>
        <div className="mt-8 text-center">
          <p className="text-lg">AI-Powered Code Review Platform</p>
          <p className="text-gray-600 mt-2">Ready for production deployment!</p>
        </div>
      </div>
    </div>
  )
}

export default App
