package com.taskmanager.service;

import com.taskmanager.dto.TaskRequest;
import com.taskmanager.dto.TaskResponse;
import com.taskmanager.entity.Task;
import com.taskmanager.entity.TaskStatus;
import com.taskmanager.entity.User;
import com.taskmanager.exception.ResourceNotFoundException;
import com.taskmanager.repository.TaskRepository;
import com.taskmanager.repository.UserRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TaskService {

	private final TaskRepository taskRepository;
	private final UserRepository userRepository;

	@Transactional(readOnly = true)
	public List<TaskResponse> listTasks(String email, TaskStatus status, String search) {
		User user = getUser(email);
		return taskRepository.searchUserTasks(user, status, search).stream()
				.map(TaskResponse::from)
				.toList();
	}

	@Transactional
	public TaskResponse createTask(String email, TaskRequest request) {
		User user = getUser(email);
		Task task = Task.builder()
				.title(request.getTitle().trim())
				.description(request.getDescription())
				.status(request.getStatus())
				.user(user)
				.build();
		return TaskResponse.from(taskRepository.save(task));
	}

	@Transactional
	public TaskResponse updateTask(String email, Long id, TaskRequest request) {
		User user = getUser(email);
		Task task = taskRepository.findByIdAndUser(id, user)
				.orElseThrow(() -> new ResourceNotFoundException("Tache introuvable"));

		task.setTitle(request.getTitle().trim());
		task.setDescription(request.getDescription());
		task.setStatus(request.getStatus());
		return TaskResponse.from(taskRepository.save(task));
	}

	@Transactional
	public void deleteTask(String email, Long id) {
		User user = getUser(email);
		Task task = taskRepository.findByIdAndUser(id, user)
				.orElseThrow(() -> new ResourceNotFoundException("Tache introuvable"));
		taskRepository.delete(task);
	}

	private User getUser(String email) {
		return userRepository.findByEmail(email)
				.orElseThrow(() -> new UsernameNotFoundException("Utilisateur introuvable"));
	}
}
