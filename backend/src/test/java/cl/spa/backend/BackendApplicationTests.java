package cl.spa.backend;

import cl.spa.backend.controller.PlanController;
import cl.spa.backend.model.Plan;
import cl.spa.backend.repository.PlanRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;  // ← cambio aquí
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(PlanController.class)
class BackendApplicationTests {

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    PlanRepository repository;

    @Test
    void getPlanes_retornaListaDePlanes() throws Exception {
        var planes = List.of(
            new Plan("Básico",  "Acceso estándar", 29990.0),
            new Plan("Premium", "Acceso completo", 59990.0)
        );
        org.mockito.Mockito.when(repository.findAll()).thenReturn(planes);

        mockMvc.perform(get("/api/planes"))
               .andExpect(status().isOk())
               .andExpect(jsonPath("$.length()").value(2))
               .andExpect(jsonPath("$[0].nombre").value("Básico"))
               .andExpect(jsonPath("$[1].nombre").value("Premium"));
    }

    @Test
    void getPlanes_retorna200() throws Exception {
        org.mockito.Mockito.when(repository.findAll()).thenReturn(List.of());

        mockMvc.perform(get("/api/planes"))
               .andExpect(status().isOk())
               .andExpect(content().contentType("application/json"));
    }
}