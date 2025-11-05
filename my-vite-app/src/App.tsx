import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import jenkinsPipeline from './assets/jenkins-full-pipeline-1tier-app.svg'
import './App.css'

function App() {

  return (
    <>
      <div>
        <a href="https://vite.dev" target="_blank">
          <img src={viteLogo} className="logo" alt="Vite logo" />
        </a>
        <a href="https://react.dev" target="_blank">
          <img src={reactLogo} className="logo react" alt="React logo" />
        </a>
      </div>
      <h1>Vite + React</h1>
      <p>By Emmanuel Romero</p>
      <div>
        <img src={jenkinsPipeline} alt="Jenkins Full Pipeline Architecture" style={{ maxWidth: '100%', height: 'auto' }} />
      </div>
    </>
  )
}

export default App
