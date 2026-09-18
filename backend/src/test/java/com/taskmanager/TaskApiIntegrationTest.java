package com.taskmanager;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
class TaskApiIntegrationTest {

	@Autowired
	private MockMvc mockMvc;

	@Autowired
	private ObjectMapper objectMapper;

	@Test
	void tasksRequireAuthentication() throws Exception {
		mockMvc.perform(get("/api/tasks"))
				.andExpect(status().isForbidden());
	}

	@Test
	void ownerCanCrudAndFilterTasks() throws Exception {
		String token = registerAndGetToken("owner-" + System.nanoTime() + "@exemple.com", "Owner User");

		MvcResult created = mockMvc.perform(post("/api/tasks")
						.header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
						.contentType(MediaType.APPLICATION_JSON)
						.content("""
								{
								  "title": "Preparer la demo",
								  "description": "Slides et API",
								  "status": "TODO"
								}
								"""))
				.andExpect(status().isCreated())
				.andExpect(jsonPath("$.id").isNumber())
				.andExpect(jsonPath("$.title").value("Preparer la demo"))
				.andExpect(jsonPath("$.status").value("TODO"))
				.andReturn();

		long taskId = objectMapper.readTree(created.getResponse().getContentAsString()).get("id").asLong();

		mockMvc.perform(post("/api/tasks")
						.header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
						.contentType(MediaType.APPLICATION_JSON)
						.content("""
								{
								  "title": "Autre tache",
								  "description": "Sans rapport",
								  "status": "IN_PROGRESS"
								}
								"""))
				.andExpect(status().isCreated());

		mockMvc.perform(get("/api/tasks")
						.header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
						.param("status", "TODO")
						.param("search", "demo"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(1))
				.andExpect(jsonPath("$[0].title").value("Preparer la demo"));

		mockMvc.perform(put("/api/tasks/" + taskId)
						.header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
						.contentType(MediaType.APPLICATION_JSON)
						.content("""
								{
								  "title": "Demo terminee",
								  "description": "Slides ok",
								  "status": "DONE"
								}
								"""))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.title").value("Demo terminee"))
				.andExpect(jsonPath("$.status").value("DONE"));

		mockMvc.perform(delete("/api/tasks/" + taskId)
						.header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
				.andExpect(status().isNoContent());

		mockMvc.perform(get("/api/tasks")
						.header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
						.param("search", "Demo"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(0));
	}

	@Test
	void userCannotAccessAnotherUsersTask() throws Exception {
		String ownerToken = registerAndGetToken("owner2-" + System.nanoTime() + "@exemple.com", "Owner Two");
		String otherToken = registerAndGetToken("other-" + System.nanoTime() + "@exemple.com", "Other User");

		MvcResult created = mockMvc.perform(post("/api/tasks")
						.header(HttpHeaders.AUTHORIZATION, "Bearer " + ownerToken)
						.contentType(MediaType.APPLICATION_JSON)
						.content("""
								{
								  "title": "Privee",
								  "description": "Ne pas partager",
								  "status": "TODO"
								}
								"""))
				.andExpect(status().isCreated())
				.andReturn();

		long taskId = objectMapper.readTree(created.getResponse().getContentAsString()).get("id").asLong();

		mockMvc.perform(get("/api/tasks")
						.header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(0));

		mockMvc.perform(put("/api/tasks/" + taskId)
						.header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken)
						.contentType(MediaType.APPLICATION_JSON)
						.content("""
								{
								  "title": "Hack",
								  "description": "x",
								  "status": "DONE"
								}
								"""))
				.andExpect(status().isNotFound());

		mockMvc.perform(delete("/api/tasks/" + taskId)
						.header(HttpHeaders.AUTHORIZATION, "Bearer " + otherToken))
				.andExpect(status().isNotFound());
	}

	private String registerAndGetToken(String email, String fullName) throws Exception {
		MvcResult result = mockMvc.perform(post("/api/auth/register")
						.contentType(MediaType.APPLICATION_JSON)
						.content("""
								{
								  "email": "%s",
								  "password": "secret123",
								  "fullName": "%s"
								}
								""".formatted(email, fullName)))
				.andExpect(status().isCreated())
				.andReturn();

		JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
		return json.get("token").asText();
	}
}
