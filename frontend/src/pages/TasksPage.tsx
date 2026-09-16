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
  const [modalOpen, setModalOpen] = useState(false)
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

  const closeModal = useCallback(() => {
    setModalOpen(false)
    setEditingId(null)
    setForm(EMPTY_FORM)
  }, [])

  useEffect(() => {
    if (!modalOpen) return
    function onKey(event: KeyboardEvent) {
      if (event.key === 'Escape') closeModal()
    }
    document.addEventListener('keydown', onKey)
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.style.overflow = ''
    }
  }, [modalOpen, closeModal])

  function openCreate() {
    setEditingId(null)
    setForm(EMPTY_FORM)
    setModalOpen(true)
  }

  function startEdit(task: Task) {
    setEditingId(task.id)
    setForm({
      title: task.title,
      description: task.description ?? '',
      status: task.status,
    })
    setModalOpen(true)
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
      closeModal()
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
      if (editingId === id) closeModal()
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
        <div className="header-actions">
          <button type="button" onClick={openCreate} className="ui-btn ui-btn-primary">
            Nouvelle tache
          </button>
          <button type="button" onClick={logout} className="ui-btn ui-btn-ghost">
            Se deconnecter
          </button>
        </div>
      </header>

      <section className="ui-panel anim-panel anim-delay-1">
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
          <div className="empty-state">
            <p className="ui-empty">Aucune tache pour le moment.</p>
            <button type="button" onClick={openCreate} className="ui-btn ui-btn-primary">
              Creer ma premiere tache
            </button>
          </div>
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
                      <span className={`ui-badge badge-${task.status.toLowerCase()}`}>
                        {STATUS_LABELS[task.status]}
                      </span>
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

      {modalOpen && (
        <div
          className="modal-backdrop"
          onClick={(e) => {
            if (e.target === e.currentTarget) closeModal()
          }}
          role="presentation"
        >
          <div className="modal-card" role="dialog" aria-modal="true" aria-labelledby="task-modal-title">
            <div className="modal-header">
              <h2 id="task-modal-title" className="ui-section-title">
                {editingId ? 'Modifier la tache' : 'Nouvelle tache'}
              </h2>
              <button type="button" className="modal-close" onClick={closeModal} aria-label="Fermer">
                ×
              </button>
            </div>

            <form className="ui-stack" onSubmit={onSubmit}>
              <label className="ui-label">
                <span>Titre</span>
                <input
                  required
                  autoFocus
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

              <div className="modal-actions">
                <button type="button" onClick={closeModal} className="ui-btn ui-btn-ghost">
                  Annuler
                </button>
                <button type="submit" disabled={saving} className="ui-btn ui-btn-primary btn-grow">
                  {saving ? 'Enregistrement...' : editingId ? 'Mettre a jour' : 'Creer la tache'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
