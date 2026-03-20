package cl.spa.backend;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import cl.spa.backend.repository.PlanRepository;
import java.util.List;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class BackendApplicationTests {

    @Autowired
    MockMvc mockMvc;

    @MockitoBean
    PlanRepository repository;

    @Test
    void getPlanes_retornaListaDePlanes() throws Exception {
        var planes = List.of(
            new cl.spa.backend.model.Plan("Básico",  "Acceso estándar", 29990.0),
            new cl.spa.backend.model.Plan("Premium", "Acceso completo", 59990.0)
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
        mockMvc.perform(get("/api/planes"))
               .andExpect(status().isOk())
               .andExpect(content().contentType("application/json"));
    }
}