package com.englishstudy.app

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import com.englishstudy.app.auth.GoogleSignInHelper
import com.englishstudy.app.databinding.ActivityMainBinding
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount

class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private lateinit var googleSignInHelper: GoogleSignInHelper
    
    private val signInLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
        val account = googleSignInHelper.handleSignInResult(task)
        
        if (account != null) {
            // Sign-in successful
            updateUI(account)
            Toast.makeText(this, "Google Sign-In successful!", Toast.LENGTH_SHORT).show()
            navigateToYouTubeLearning()
        } else {
            // Sign-in failed
            Toast.makeText(this, "Google Sign-In failed. Please check your internet connection and try again.", Toast.LENGTH_LONG).show()
            updateUI(null)
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        googleSignInHelper = GoogleSignInHelper(this)
        
        setupUI()
        checkExistingSignIn()
    }
    
    private fun setupUI() {
        binding.signInButton.setOnClickListener {
            signIn()
        }
        
        binding.signOutButton.setOnClickListener {
            signOut()
        }
        
        binding.continueButton.setOnClickListener {
            navigateToYouTubeLearning()
        }
    }
    
    private fun checkExistingSignIn() {
        val account = googleSignInHelper.getCurrentAccount()
        updateUI(account)
        
        // If already signed in, navigate to YouTube learning
        if (account != null) {
            navigateToYouTubeLearning()
        }
    }
    
    private fun signIn() {
        val signInIntent = googleSignInHelper.getSignInIntent()
        signInLauncher.launch(signInIntent)
    }
    
    private fun signOut() {
        googleSignInHelper.signOut()
        updateUI(null)
        Toast.makeText(this, "Signed out", Toast.LENGTH_SHORT).show()
    }
    
    private fun updateUI(account: GoogleSignInAccount?) {
        if (account != null) {
            // Signed in
            binding.statusText.text = "Welcome, ${account.displayName ?: account.email}"
            binding.signInButton.isEnabled = false
            binding.signOutButton.isEnabled = true
            binding.continueButton.isEnabled = true
        } else {
            // Signed out
            binding.statusText.text = "Please sign in with your Google account to continue"
            binding.signInButton.isEnabled = true
            binding.signOutButton.isEnabled = false
            binding.continueButton.isEnabled = false
        }
    }
    
    private fun navigateToYouTubeLearning() {
        val intent = Intent(this, YouTubeLearningActivity::class.java)
        startActivity(intent)
    }
}