package com.example.claudedemo

import android.app.Activity
import android.os.Bundle
import android.widget.Button
import android.widget.TextView

class MainActivity : Activity() {

    private var count = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val counterText = findViewById<TextView>(R.id.counterText)
        val tapButton = findViewById<Button>(R.id.tapButton)
        val resetButton = findViewById<Button>(R.id.resetButton)

        count = savedInstanceState?.getInt("count") ?: 0
        counterText.text = count.toString()

        tapButton.setOnClickListener {
            count++
            counterText.text = count.toString()
        }
        resetButton.setOnClickListener {
            count = 0
            counterText.text = "0"
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putInt("count", count)
    }
}
