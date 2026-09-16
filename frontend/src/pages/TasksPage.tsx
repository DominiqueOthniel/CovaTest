import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { ApiError, api } from '../api'
import { useAuth } from '../context/AuthContext'
import { useToast } from '../context/ToastContext'
import type { Task, TaskStatus } from '../types'

const STATUS_LABELS: Record<TaskStatus | 'ALL', string> = {
  ALL: 'Tous',
  TODO: 'A faire',
  IN_PROGRESS: 'En cours',
  DONE: 'Termine',
}

const EMPTY_FORM = {
  title: '',
  description: '',
  status: 'TODO' as TaskStatus,
}

export default function TasksPage() {
  const { user, logout } = useAuth()
  const { notify } = useToast()
  const [tasks, setTasks] = useState<Task[]>([])
  const [statusFilter, setStatusFilter] = useState<TaskStatus | 'ALL'>('ALL')
  const [search, setSearch] = useState('')
  const [form, setForm] = useState(EMPTY_FORM)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  const loadTasks = useCallback(async () => {
    if (!user) return
    setLoading(true)
    try {
      const data = await api.listTasks(user.token, statusFilter, search)
      setTasks(data)
    } catch (error) {
      const message = error instanceof ApiError ? error.message : 'Impossible de charger les taches'
      notify(message, 'error')
      if (error instanceof ApiError && error.status === 401) logout()
    } finally {
      setLoading(false)
    }
  }, [user, statusFilter, search, notify, logout])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadTasks()
    }, 250)
    return () => window.clearTimeout(timer)
  }, [loadTasks])

  function startEdit(task: Task) {
    setEditingId(task.id)
    setForm({
      title: task.title,
      description: task.description ?? '',
      status: task.status,
    })
  }

  function resetForm() {
    setEditingId(null)
    setForm(EMPTY_FORM)
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    if (!user) return
    setSaving(true)
    try {
      if (editingId) {
        await api.updateTask(user.token, editingId, form)
        notify('Tache mise a jour', 'success')
      } else {
        await api.createTask(user.token, form)
        notify('Tache creee', 'success')
      }
      resetForm()
      await loadTasks()
    } catch (error) {
      const message = error instanceof ApiError ? error.message : 'Echec de la sauvegarde'
      notify(message, 'error')
    } finally {
      setSaving(false)
    }
  }

  async function onDelete(id: number) {
    if (!user) return
    if (!window.confirm('Supprimer cette tache ?')) return
    try {
      await api.deleteTask(user.token, id)
      notify('Tache supprimee', 'success')
      if (editingId === id) resetForm()
      await loadTasks()
    } catch (error) {
      const message = error instanceof ApiError ? error.message : 'Echec de la suppression'
      notify(message, 'error')
    }
  }

  return (
    <div className="ui-page anim-page">
      <header className="ui-panel tasks-header anim-panel">
        <div>
          <p className="ui-eyebrow">Task Manager</p>
          <h1 className="ui-title">Bonjour {user?.fullName}</h1>
          <p className="ui-subtitle">{user?.email}</p>
        </div>
        <button type="button" onClick={logout} className="ui-btn ui-btn-ghost">
          Se deconnecter
        </button>
      </header>

      <div className="tasks-layout">
        <form onSubmit={onSubmit} className="ui-panel ui-stack anim-panel anim-delay-1">
          <h2 className="ui-section-title">
            {editingId ? 'Modifier la tache' : 'Nouvelle tache'}
          </h2>

          <label className="ui-label">
            <span>Titre</span>
            <input
              required
              className="ui-input"
              value={form.title}
              onChange={(e) => setForm((prev) => ({ ...prev, title: e.target.value }))}
              placeholder="Preparer la demo"
            />
          </label>

          <label className="ui-label">
            <span>Description</span>
            <textarea
              rows={4}
              className="ui-textarea"
              value={form.description}
              onChange={(e) => setForm((prev) => ({ ...prev, description: e.target.value }))}
              placeholder="Details optionnels"
            />
          </label>

          <label className="ui-label">
            <span>Statut</span>
            <select
              className="ui-select"
              value={form.status}
              onChange={(e) => setForm((prev) => ({ ...prev, status: e.target.value as TaskStatus }))}
            >
              <option value="TODO">A faire</option>
              <option value="IN_PROGRESS">En cours</option>
              <option value="DONE">Termine</option>
            </select>
          </label>

          <div className="ui-row">
            <button type="submit" disabled={saving} className="ui-btn ui-btn-primary btn-grow">
              {saving ? 'Enregistrement...' : editingId ? 'Mettre a jour' : 'Ajouter'}
            </button>
            {editingId && (
              <button type="button" onClick={resetForm} className="ui-btn ui-btn-ghost">
                Annuler
              </button>
            )}
          </div>
        </form>

        <section className="ui-panel anim-panel anim-delay-2">
          <div className="tasks-toolbar">
            <input
              className="ui-input"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Rechercher une tache..."
            />
            <select
              className="ui-select"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as TaskStatus | 'ALL')}
            >
              {Object.entries(STATUS_LABELS).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
          </div>

          {loading ? (
            <p className="ui-empty ui-loading">Chargement des taches...</p>
          ) : tasks.length === 0 ? (
            <p className="ui-empty">Aucune tache pour le moment.</p>
          ) : (
            <ul className="ui-list">
              {tasks.map((task, index) => (
                <li
                  key={task.id}
                  className="ui-list-item anim-item"
                  style={{ animationDelay: `${Math.min(index, 8) * 45}ms` }}
                >
                  <div className="task-item-main">
                    <div>
                      <div className="ui-row row-center">
                        <h3 className="task-title">{task.title}</h3>
                        <span className="ui-badge">{STATUS_LABELS[task.status]}</span>
                      </div>
                      {task.description && (
                        <p className="ui-subtitle">{task.description}</p>
                      )}
                      <p className="ui-subtitle task-meta">
                        Mise a jour : {new Date(task.updatedAt).toLocaleString('fr-FR')}
                      </p>
                    </div>
                    <div className="task-item-actions">
                      <button type="button" onClick={() => startEdit(task)} className="ui-btn ui-btn-ghost ui-btn-sm">
                        Editer
                      </button>
                      <button
                        type="button"
                        onClick={() => void onDelete(task.id)}
                        className="ui-btn ui-btn-danger ui-btn-sm"
                      >
                        Supprimer
                      </button>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>
    </div>
  )
}
