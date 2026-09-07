package com.gestao.leiteira.controller;

import com.gestao.leiteira.model.User;
import com.gestao.leiteira.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserRepository repository;

    @GetMapping
    public List<User> getAll() {
        return repository.findAll();
    }

    @PostMapping("/signup")
    public ResponseEntity<?> signup(@RequestBody User user) {
        if (repository.findByUsername(user.getUsername()).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("Username já existe.");
        }
        // Em um sistema real, a senha deve ser criptografada (ex: BCrypt) antes de salvar.
        // Como o app mobile está enviando em texto puro, vamos manter simples para iniciar.
        User savedUser = repository.save(user);
        return ResponseEntity.status(HttpStatus.CREATED).body(savedUser);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User loginRequest) {
        Optional<User> userOpt = repository.findByUsername(loginRequest.getUsername());
        
        if (userOpt.isPresent()) {
            User user = userOpt.get();
            // Comparação simples de senha em texto puro.
            if (user.getPassword().equals(loginRequest.getPassword())) {
                return ResponseEntity.ok(user);
            }
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Credenciais inválidas.");
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getById(@PathVariable Long id) {
        return repository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody User updated) {
        return repository.findById(id).map(user -> {
            // Impede duplicidade de username ao editar
            Optional<User> byUsername = repository.findByUsername(updated.getUsername());
            if (byUsername.isPresent() && !byUsername.get().getId().equals(id)) {
                return ResponseEntity.status(HttpStatus.CONFLICT).body("Username já existe.");
            }
            user.setUsername(updated.getUsername());
            user.setNomeCompleto(updated.getNomeCompleto());
            user.setEmail(updated.getEmail());
            user.setTelefone(updated.getTelefone());
            user.setRole(updated.getRole());
            if (updated.getAtivo() != null) user.setAtivo(updated.getAtivo());
            // Só troca a senha se enviada e não vazia
            if (updated.getPassword() != null && !updated.getPassword().isBlank()) {
                user.setPassword(updated.getPassword());
            }
            return ResponseEntity.ok(repository.save(user));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (!repository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        repository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
