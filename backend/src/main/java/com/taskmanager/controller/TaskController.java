package com.taskmanager.controller;

import com.taskmanager.dto.TaskRequest;
import com.taskmanager.dto.TaskResponse;
import com.taskmanager.entity.TaskStatus;
import com.taskmanager.service.TaskService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class TaskController {

	private final TaskService taskService;

	@GetMapping
	public List<TaskResponse> listTasks(
			Authentication authentication,
			@RequestParam(required = false) TaskStatus status,
			@RequestParam(required = false) String search) {
		return taskService.listTasks(authentication.getName(), status, search);
	}

	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public TaskResponse createTask(
			Authentication authentication,
			@Valid @RequestBody TaskRequest request) {
		return taskService.createTask(authentication.getName(), request);
	}

	@PutMapping("/{id}")
	public TaskResponse updateTask(
			Authentication authentication,
			@PathVariable Long id,
			@Valid @RequestBody TaskRequest request) {
		return taskService.updateTask(authentication.getName(), id, request);
	}

	@DeleteMapping("/{id}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void deleteTask(Authentication authentication, @PathVariable Long id) {
		taskService.deleteTask(authentication.getName(), id);
	}
}
