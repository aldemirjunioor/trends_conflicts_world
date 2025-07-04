
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('Login successful');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('Failed to log in: ${e.message}');
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return 'Nenhum usuário encontrado com este e-mail.';
      } else if (e.code == 'wrong-password') {
        return 'Senha incorreta. Por favor, tente novamente.';
      } else {
        return 'Ocorreu um erro ao fazer login.';
      }
    }
  }

  Future<String?> register(String fullName, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await userCredential.user?.updateDisplayName(fullName);
      await userCredential.user?.reload();
      
      debugPrint('Registration successful: ${userCredential.user?.email}');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('Failed to register: ${e.message}');
      if (e.code == 'weak-password') {
        return 'A senha fornecida é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        return 'Este e-mail já está em uso.';
      } else {
        return 'Ocorreu um erro ao se registrar.';
      }
    } catch (e) {
      debugPrint('An unexpected error occurred: $e');
      return 'Ocorreu um erro inesperado.';
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('Failed to send password reset email: ${e.message}');
      return 'Falha ao enviar o e-mail de recuperação.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
