package com.gestao.leiteira.service;

import com.gestao.leiteira.exception.ApiException;
import com.gestao.leiteira.model.User;
import com.gestao.leiteira.repository.UserRepository;
import com.gestao.leiteira.security.PasswordHasher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.Set;

@Service
public class UserService {

    public static final String ROLE_ADMIN = "ADMIN";
    public static final String ROLE_OPERADOR = "OPERADOR";
    private static final Set<String> ROLES = Set.of(ROLE_ADMIN, ROLE_OPERADOR);
    private static final int SENHA_MINIMA = 4;

    private final UserRepository repository;
    private final PasswordHasher passwordHasher;

    public UserService(UserRepository repository, PasswordHasher passwordHasher) {
        this.repository = repository;
        this.passwordHasher = passwordHasher;
    }

    public List<User> findAll() {
        return repository.findAllByOrderByUsernameAsc();
    }

    public User findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Usuário não encontrado."));
    }

    /**
     * Cadastro público (tela "Cadastre-se"): sempre cria OPERADOR, exceto o
     * primeiro usuário do sistema, que vira ADMIN para poder gerenciar os demais.
     */
    @Transactional
    public User signup(User user) {
        user.setRole(repository.count() == 0 ? ROLE_ADMIN : ROLE_OPERADOR);
        user.setAtivo(true);
        return create(user);
    }

    /** Criação pela tela de gerenciamento de usuários (permite escolher o perfil). */
    @Transactional
    public User create(User user) {
        user.setId(null);
        user.setUsername(Validacoes.texto(user.getUsername(), "usuário"));
        validatePassword(user.getPassword());
        user.setRole(normalizeRole(user.getRole()));
        if (user.getAtivo() == null) user.setAtivo(true);
        ensureUniqueUsername(user.getUsername(), null);
        user.setPassword(passwordHasher.hash(user.getPassword()));
        return repository.save(user);
    }

    @Transactional
    public User login(String username, String password) {
        User user = Optional.ofNullable(username)
                .flatMap(u -> repository.findByUsername(u.trim()))
                .filter(u -> passwordHasher.matches(password, u.getPassword()))
                .orElseThrow(() -> ApiException.unauthorized("Usuário ou senha incorretos."));
        if (!Boolean.TRUE.equals(user.getAtivo())) {
            throw ApiException.forbidden("Usuário inativo. Procure o administrador.");
        }
        // Migra senhas legadas (texto puro) para hash no primeiro login
        if (!passwordHasher.isHashed(user.getPassword())) {
            user.setPassword(passwordHasher.hash(password));
            repository.save(user);
        }
        return user;
    }

    @Transactional
    public User update(Long id, User dados) {
        User user = findById(id);
        String username = Validacoes.texto(dados.getUsername(), "usuário");
        ensureUniqueUsername(username, id);
        String role = normalizeRole(dados.getRole());
        boolean ativo = dados.getAtivo() == null ? Boolean.TRUE.equals(user.getAtivo()) : dados.getAtivo();
        if (!ROLE_ADMIN.equals(role) || !ativo) {
            ensureNotLastActiveAdmin(user, "Não é possível remover o perfil ou desativar o último administrador ativo.");
        }

        user.setUsername(username);
        user.setNomeCompleto(dados.getNomeCompleto());
        user.setEmail(dados.getEmail());
        user.setTelefone(dados.getTelefone());
        user.setRole(role);
        user.setAtivo(ativo);
        // Só troca a senha se enviada e não vazia
        if (dados.getPassword() != null && !dados.getPassword().isBlank()) {
            validatePassword(dados.getPassword());
            user.setPassword(passwordHasher.hash(dados.getPassword()));
        }
        return repository.save(user);
    }

    @Transactional
    public void delete(Long id) {
        User user = findById(id);
        ensureNotLastActiveAdmin(user, "Não é possível excluir o último administrador ativo.");
        repository.delete(user);
    }

    private void ensureNotLastActiveAdmin(User user, String message) {
        boolean isActiveAdmin = ROLE_ADMIN.equals(user.getRole()) && Boolean.TRUE.equals(user.getAtivo());
        if (isActiveAdmin && repository.countByRoleAndAtivoTrue(ROLE_ADMIN) <= 1) {
            throw ApiException.conflict(message);
        }
    }

    private void ensureUniqueUsername(String username, Long currentId) {
        repository.findByUsername(username)
                .filter(existing -> !existing.getId().equals(currentId))
                .ifPresent(existing -> {
                    throw ApiException.conflict("O usuário \"" + username + "\" já existe.");
                });
    }

    private void validatePassword(String password) {
        if (password == null || password.length() < SENHA_MINIMA) {
            throw ApiException.badRequest("A senha deve ter pelo menos " + SENHA_MINIMA + " caracteres.");
        }
    }

    private String normalizeRole(String role) {
        if (role == null || role.isBlank()) return ROLE_OPERADOR;
        String normalized = role.trim().toUpperCase();
        if (!ROLES.contains(normalized)) {
            throw ApiException.badRequest("Perfil inválido. Use ADMIN ou OPERADOR.");
        }
        return normalized;
    }
}
