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
        <img src={jenkinsPipeline} alt="Jenkins Pipeline Diagram"
          style={{ width: '100%', height: 'auto', border: '1px solid #FFF', borderRadius: '9px', padding: '2rem', backgroundColor: '#121212' }} />
      </div>
    </>
  )
}

export default App
