# WITHOUT local (Global Scope)
#my_func() {
#    name="Alice"
#}
#name="Bob"
#my_func
#echo $name  # Outputs: Alice (Bob was overwritten!)

# WITH local (Local Scope)
my_func() {
    name="Alice"
}
#name="Bob"
my_func
#echo $name  # Outputs: Bob (The global variable stayed safe)

