import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { ApiError } from '../api'
import { useAuth } from '../context/AuthContext'
import { useToast } from '../context/ToastContext'

interface AuthPageProps {
  mode: 'login' | 'register'
}

export default function AuthPage({ mode }: AuthPageProps) {
  const { login, register } = useAuth()
  const { notify } = useToast()
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setLoading(true)
    try {
      if (mode === 'login') {
        await login(email, password)
        notify('Connexion reussie', 'success')
      } else {
        await register(fullName, email, password)
        notify('Compte cree avec succes', 'success')
      }
    } catch (error) {
      const message = error instanceof ApiError ? error.message : 'Echec de la requete'
      notify(message, 'error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="ui-page ui-page-center anim-page">
      <div className="auth-shell">
        <section className="auth-hero">
          <div className="auth-hero-glow auth-hero-glow-a" />
          <div className="auth-hero-glow auth-hero-glow-b" />
          <p className="ui-eyebrow">Task Manager</p>
          <h1 className="ui-title">
            Organisez vos taches, web et mobile, au meme rythme.
          </h1>
          <p className="ui-subtitle">
            Une API Spring Boot securisee par JWT, un frontend React moderne, et une sync prete pour Flutter.
          </p>
        </section>

        <section className="auth-form">
          <h2 className="ui-title">
            {mode === 'login' ? 'Connexion' : 'Creer un compte'}
          </h2>
          <p className="ui-subtitle">
            {mode === 'login'
              ? 'Accedez a votre liste de taches.'
              : 'Inscrivez-vous pour demarrer.'}
          </p>

          <form className="ui-stack auth-form-stack" onSubmit={onSubmit}>
            {mode === 'register' && (
              <label className="ui-label">
                <span>Nom complet</span>
                <input
                  required
                  className="ui-input"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="votre nom"
                />
              </label>
            )}

            <label className="ui-label">
              <span>Email</span>
              <input
                required
                type="email"
                className="ui-input"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="yourname@exemple.com"
              />
            </label>

            <label className="ui-label">
              <span>Mot de passe</span>
              <input
                required
                type="password"
                minLength={6}
                className="ui-input"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Minimum 6 caracteres"
              />
            </label>

            <button type="submit" disabled={loading} className="ui-btn ui-btn-primary ui-btn-block">
              {loading ? 'Patientez...' : mode === 'login' ? 'Se connecter' : "S'inscrire"}
            </button>
          </form>

          <p className="ui-subtitle auth-switch">
            {mode === 'login' ? (
              <>
                Pas encore de compte ? <Link to="/register">Creer un compte</Link>
              </>
            ) : (
              <>
                Deja inscrit ? <Link to="/login">Se connecter</Link>
              </>
            )}
          </p>
        </section>
      </div>
    </div>
  )
}
