package com.gestao.leiteira.service;

import com.gestao.leiteira.exception.ApiException;
import com.gestao.leiteira.model.Production;
import com.gestao.leiteira.repository.ProductionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
public class ProductionService {

    private final ProductionRepository repository;
    private final AnimalService animalService;

    public ProductionService(ProductionRepository repository, AnimalService animalService) {
        this.repository = repository;
        this.animalService = animalService;
    }

    /** Todos os registros ou, se informado, só os a partir de {@code desde}. */
    public List<Production> findAll(LocalDate desde) {
        return desde == null
                ? repository.findAllByOrderByDataDesc()
                : repository.findByDataGreaterThanEqualOrderByDataDesc(desde.atStartOfDay());
    }

    public List<Production> findByAnimal(Long animalId) {
        return repository.findByAnimalIdOrderByDataDesc(animalId);
    }

    public Production findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Registro de produção não encontrado."));
    }

    @Transactional
    public Production create(Production production) {
        production.setId(null);
        validate(production);
        production.setAnimal(animalService.resolve(production.getAnimal()));
        return repository.save(production);
    }

    @Transactional
    public Production update(Long id, Production dados) {
        Production production = findById(id);
        validate(dados);
        production.setAnimal(animalService.resolve(dados.getAnimal()));
        production.setData(dados.getData());
        production.setQuantidade(dados.getQuantidade());
        return repository.save(production);
    }

    @Transactional
    public void delete(Long id) {
        repository.delete(findById(id));
    }

    private void validate(Production production) {
        Validacoes.obrigatorio(production.getData(), "data");
        Validacoes.positivo(production.getQuantidade(), "quantidade");
    }
}
