package com.gestao.leiteira.service;

import com.gestao.leiteira.exception.ApiException;
import com.gestao.leiteira.model.Reproduction;
import com.gestao.leiteira.repository.ReproductionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ReproductionService {

    static final String TIPO_PARTO = "Parto";

    private final ReproductionRepository repository;
    private final AnimalService animalService;

    public ReproductionService(ReproductionRepository repository, AnimalService animalService) {
        this.repository = repository;
        this.animalService = animalService;
    }

    public List<Reproduction> findAll() {
        return repository.findAllByOrderByDataDesc();
    }

    public List<Reproduction> findByAnimal(Long animalId) {
        return repository.findByAnimalIdOrderByDataDesc(animalId);
    }

    public Reproduction findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Registro reprodutivo não encontrado."));
    }

    @Transactional
    public Reproduction create(Reproduction reproduction) {
        reproduction.setId(null);
        validate(reproduction);
        reproduction.setAnimal(animalService.resolve(reproduction.getAnimal()));
        if (reproduction.getStatus() == null || reproduction.getStatus().isBlank()) {
            reproduction.setStatus("Pendente");
        }
        Reproduction saved = repository.save(reproduction);
        if (TIPO_PARTO.equals(saved.getTipo())) {
            animalService.markAsLactating(saved.getAnimal());
        }
        return saved;
    }

    @Transactional
    public Reproduction update(Long id, Reproduction dados) {
        Reproduction reproduction = findById(id);
        validate(dados);
        // Só altera o status do animal quando o evento passa a ser um parto,
        // para não sobrescrever mudanças posteriores (ex.: secagem).
        boolean virouParto = TIPO_PARTO.equals(dados.getTipo())
                && !TIPO_PARTO.equals(reproduction.getTipo());
        reproduction.setAnimal(animalService.resolve(dados.getAnimal()));
        reproduction.setTipo(dados.getTipo());
        reproduction.setData(dados.getData());
        reproduction.setTouro(dados.getTouro());
        reproduction.setPrevisaoParto(dados.getPrevisaoParto());
        if (dados.getStatus() != null && !dados.getStatus().isBlank()) {
            reproduction.setStatus(dados.getStatus());
        }
        reproduction.setObservacao(dados.getObservacao());
        Reproduction saved = repository.save(reproduction);
        if (virouParto) {
            animalService.markAsLactating(saved.getAnimal());
        }
        return saved;
    }

    @Transactional
    public void delete(Long id) {
        repository.delete(findById(id));
    }

    private void validate(Reproduction reproduction) {
        reproduction.setTipo(Validacoes.texto(reproduction.getTipo(), "tipo"));
        Validacoes.obrigatorio(reproduction.getData(), "data");
    }
}
