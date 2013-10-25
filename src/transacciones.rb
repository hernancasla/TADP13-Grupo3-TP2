require_relative 'motor_de_aspectos'
require_relative 'join_point'
require_relative 'advice'

class AdviceTransaccion
  attr_accessor :autocommit

  def initialize(objeto)
    @objeto = objeto
    @objeto_copia = objeto.dup
  end

  def modificar_objecto

    crear_metodos_transacciones

    motor = MotorDeAspectos.new

    proc = Proc.new { |clase, simbolo, simbolo_original, instancia|
      atributo_simbolo = "@#{simbolo}".to_sym
      @objeto_copia.instance_variable_get(atributo_simbolo)
    }

    advice = AdviceEnLugarDe.new(proc)

    point_cut = JoinPointMetodosAccessors.new(@objeto.class).y((JoinPointNombreMetodo.new(/^(\w+)=$/)).no)

    motor.aspecto(point_cut,advice,@objeto.singleton_class)

    proc = Proc.new { |clase, simbolo, simbolo_original, instancia, valor|
      atributo_simbolo = "@#{simbolo}".chop.to_sym
      @objeto_copia.instance_variable_set(atributo_simbolo,valor)
    }

    advice = AdviceEnLugarDe.new(proc)

    point_cut = JoinPointMetodosAccessors.new(@objeto.class).y(JoinPointNombreMetodo.new(/^(\w+)=$/))

    motor.aspecto(point_cut,advice,@objeto.singleton_class)

    if(@autocommit)
      advice = AdviceDespues.new(Proc.new{puts 'advice despues'})

      point_cut = JoinPointMetodosAccessors.new(@objeto.class).y(JoinPointNombreMetodo.new(/^(\w+)=$/))

      motor.aspecto(point_cut,advice,@objeto.singleton_class)
    end

  end

  private

  def crear_metodos_transacciones

    adivce_transaccion = self
    objecto_copia = @objeto_copia

    @objeto.singleton_class.class_eval do

      define_method(:commit) do
        objecto_copia.instance_variables.each do |atributo|
          valor = objecto_copia.instance_variable_get(atributo)
          self.instance_variable_set(atributo,valor)
        end
      end

      define_method(:rollback) do
        adivce_transaccion.instance_variable_set(:@objeto_copia,self.dup)
      end

    end

  end

end
