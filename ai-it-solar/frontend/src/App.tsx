import React, { useState } from 'react'
import './App.css'

interface AnalysisResult {
  stats: {
    totalLines: number;
    sameLines: number;
    changedLines: number;
  };
  changes: {
    imports: any[];
    functions: any[];
    classes: any[];
    variables: any[];
  };
  diffHtml: { left: string; right: string };
  riskLevel: { level: string; text: string };
}

function App() {
  const [oldCode, setOldCode] = useState('')
  const [newCode, setNewCode] = useState('')
  const [analysis, setAnalysis] = useState<AnalysisResult | null>(null)
  const [showResults, setShowResults] = useState(false)

  const performCodeAnalysis = (oldCode: string, newCode: string): AnalysisResult => {
    const oldLines = oldCode.split('\n')
    const newLines = newCode.split('\n')
    const maxLines = Math.max(oldLines.length, newLines.length)

    let stats = {
      totalLines: maxLines,
      sameLines: 0,
      changedLines: 0
    }

    let changes = {
      imports: [] as any[],
      functions: [] as any[],
      classes: [] as any[],
      variables: [] as any[]
    }

    let diffHtml = { left: '', right: '' }

    for (let i = 0; i < maxLines; i++) {
      const oldLine = oldLines[i] || ''
      const newLine = newLines[i] || ''
      const lineNum = i + 1

      if (oldLine === newLine) {
        stats.sameLines++
        diffHtml.left += createLineHtml(lineNum, escapeHtml(oldLine), 'same')
        diffHtml.right += createLineHtml(lineNum, escapeHtml(newLine), 'same')
      } else {
        stats.changedLines++
        
        if (oldLine && newLine) {
          const highlighted = highlightDifferences(oldLine, newLine)
          diffHtml.left += createLineHtml(lineNum, highlighted.text1, 'changed')
          diffHtml.right += createLineHtml(lineNum, highlighted.text2, 'changed')
        } else if (oldLine) {
          diffHtml.left += createLineHtml(lineNum, escapeHtml(oldLine), 'removed')
          diffHtml.right += createLineHtml('', '', 'removed')
        } else {
          diffHtml.left += createLineHtml('', '', 'added')
          diffHtml.right += createLineHtml(lineNum, escapeHtml(newLine), 'added')
        }

        // Семантический анализ
        analyzeSemanticChanges(oldLine, newLine, lineNum, changes)
      }
    }

    const riskLevel = calculateRisk(changes, stats)
    return { stats, changes, diffHtml, riskLevel }
  }

  const analyzeSemanticChanges = (oldLine: string, newLine: string, lineNum: number, changes: any) => {
    const oldTrimmed = oldLine.trim()
    const newTrimmed = newLine.trim()

    // Анализ импортов
    if (oldTrimmed.match(/^(import|from|#include|require)/i) || 
        newTrimmed.match(/^(import|from|#include|require)/i)) {
      if (oldTrimmed !== newTrimmed) {
        changes.imports.push({
          type: oldTrimmed && newTrimmed ? 'modified' : (oldTrimmed ? 'removed' : 'added'),
          line: lineNum,
          old: oldTrimmed,
          new: newTrimmed,
          description: getImportDescription(oldTrimmed, newTrimmed)
        })
      }
    }

    // Анализ функций
    if (oldTrimmed.match(/^(def|function|func)/i) || 
        newTrimmed.match(/^(def|function|func)/i) ||
        oldTrimmed.match(/\w+\s*\(/) || newTrimmed.match(/\w+\s*\(/)) {
      if (oldTrimmed !== newTrimmed) {
        changes.functions.push({
          type: oldTrimmed && newTrimmed ? 'modified' : (oldTrimmed ? 'removed' : 'added'),
          line: lineNum,
          old: oldTrimmed,
          new: newTrimmed,
          description: getFunctionDescription(oldTrimmed, newTrimmed)
        })
      }
    }
  }

  const getImportDescription = (oldLine: string, newLine: string) => {
    if (!oldLine) return `Добавлен импорт: ${newLine}`
    if (!newLine) return `Удален импорт: ${oldLine}`
    return `Изменен импорт: ${oldLine} → ${newLine}`
  }

  const getFunctionDescription = (oldLine: string, newLine: string) => {
    if (!oldLine) return `Добавлена функция: ${extractFunctionName(newLine)}`
    if (!newLine) return `Удалена функция: ${extractFunctionName(oldLine)}`
    return `Изменена функция: ${extractFunctionName(oldLine)}`
  }

  const extractFunctionName = (line: string) => {
    const match = line.match(/(?:def|function|func)\s+(\w+)/i) || line.match(/(\w+)\s*\(/)
    return match ? match[1] : 'неизвестная'
  }

  const calculateRisk = (changes: any, stats: any) => {
    let riskScore = 0
    
    riskScore += changes.functions.length * 3
    riskScore += changes.classes.length * 3
    riskScore += changes.imports.length * 2
    riskScore += changes.variables.length * 1

    const changePercent = (stats.changedLines / stats.totalLines) * 100
    if (changePercent > 50) riskScore += 5
    else if (changePercent > 25) riskScore += 2

    if (riskScore <= 3) return { level: 'low', text: '🟢 Низкий риск: косметические изменения' }
    if (riskScore <= 8) return { level: 'medium', text: '🟡 Средний риск: умеренные изменения' }
    return { level: 'high', text: '🔴 Высокий риск: серьезные структурные изменения' }
  }

  const createLineHtml = (lineNum: any, content: string, lineClass: string) => {
    return `
      <div class="line ${lineClass}">
        <div class="line-number">${lineNum}</div>
        <div class="line-content">${content}</div>
      </div>
    `
  }

  const escapeHtml = (text: string) => {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  const highlightDifferences = (str1: string, str2: string) => {
    const words1 = str1.split(/(\s+)/)
    const words2 = str2.split(/(\s+)/)
    const maxLength = Math.max(words1.length, words2.length)

    let result1 = ''
    let result2 = ''

    for (let i = 0; i < maxLength; i++) {
      const word1 = words1[i] || ''
      const word2 = words2[i] || ''

      if (word1 !== word2) {
        result1 += `<span class="highlight">${escapeHtml(word1)}</span>`
        result2 += `<span class="highlight">${escapeHtml(word2)}</span>`
      } else {
        result1 += escapeHtml(word1)
        result2 += escapeHtml(word2)
      }
    }

    return { text1: result1, text2: result2 }
  }

  const analyzeCode = () => {
    if (!oldCode.trim() || !newCode.trim()) {
      alert('Пожалуйста, введите код в оба поля для анализа')
      return
    }

    const result = performCodeAnalysis(oldCode, newCode)
    setAnalysis(result)
    setShowResults(true)
  }

  const loadExample = () => {
    setOldCode(`function calculateSum(a, b) {
  return a + b;
}

const users = [];

export default calculateSum;`)

    setNewCode(`function calculateSum(a, b, c = 0) {
  return a + b + c;
}

function calculateProduct(a, b) {
  return a * b;
}

const users = [];
const products = [];

export { calculateSum, calculateProduct };`)
  }

  const clearCode = () => {
    setOldCode('')
    setNewCode('')
    setAnalysis(null)
    setShowResults(false)
  }

  return (
    <div className="app-container">
      <div className="header">
        <h1>🚀 AI IT Solar PRO</h1>
        <p className="subtitle">AI-Powered Code Review Platform</p>
      </div>

      <div className="quick-actions">
        <button onClick={loadExample} className="action-btn">
          📋 Загрузить пример
        </button>
        <button onClick={clearCode} className="action-btn">
          🗑️ Очистить
        </button>
        <button onClick={() => window.open('http://localhost:3001/health')} className="action-btn">
          🔧 Backend API
        </button>
      </div>

      <div className="input-section">
        <div className="input-block">
          <div className="input-label">📄 Исходный код (было)</div>
          <textarea
            value={oldCode}
            onChange={(e) => setOldCode(e.target.value)}
            className="code-input"
            placeholder="Вставьте здесь исходный код..."
          />
        </div>
        <div className="input-block">
          <div className="input-label">🔄 Новый код (стало)</div>
          <textarea
            value={newCode}
            onChange={(e) => setNewCode(e.target.value)}
            className="code-input"
            placeholder="Вставьте здесь новый код..."
          />
        </div>
      </div>

      <div className="controls">
        <button onClick={analyzeCode} className="analyze-btn">
          🔍 Анализировать изменения
        </button>
      </div>

      {showResults && analysis && (
        <div className="results">
          <div className="summary-card">
            <h2>📊 Сводка изменений</h2>
            <div className="stats-grid">
              <div className="stat-card">
                <span className="stat-number green">{analysis.stats.sameLines}</span>
                <div className="stat-label">Неизменных строк</div>
              </div>
              <div className="stat-card">
                <span className="stat-number red">{analysis.stats.changedLines}</span>
                <div className="stat-label">Изменений</div>
              </div>
              <div className="stat-card">
                <span className="stat-number blue">{analysis.changes.functions.length}</span>
                <div className="stat-label">Функций изменено</div>
              </div>
              <div className="stat-card">
                <span className="stat-number orange">{analysis.changes.imports.length}</span>
                <div className="stat-label">Импортов изменено</div>
              </div>
            </div>
            <div className={`risk-indicator risk-${analysis.riskLevel.level}`}>
              {analysis.riskLevel.text}
            </div>
          </div>

          <div className="changes-list">
            <h3>🔍 Детальный анализ изменений</h3>
            {analysis.changes.functions.map((change, index) => (
              <div key={index} className={`change-item ${change.type}`}>
                <div className={`change-icon ${change.type}`}>F</div>
                <div>
                  <strong>Функция (строка {change.line})</strong><br />
                  <span className="description">{change.description}</span>
                </div>
              </div>
            ))}
            {analysis.changes.imports.map((change, index) => (
              <div key={index} className={`change-item ${change.type}`}>
                <div className={`change-icon ${change.type}`}>I</div>
                <div>
                  <strong>Импорт (строка {change.line})</strong><br />
                  <span className="description">{change.description}</span>
                </div>
              </div>
            ))}
          </div>

          <div className="diff-container">
            <div className="diff-side">
              <h3>📄 Исходный код</h3>
              <div dangerouslySetInnerHTML={{ __html: analysis.diffHtml.left }} />
            </div>
            <div className="diff-side">
              <h3>🔄 Новый код</h3>
              <div dangerouslySetInnerHTML={{ __html: analysis.diffHtml.right }} />
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default App
