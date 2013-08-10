module FlawDetector
  module InsnsInfo
    VM_CALL_ARGS_BLOCKARG = (0x02 ** 2)

    NOP = 0
    GETLOCAL = 1
    SETLOCAL = 2
    GETSPECIAL = 3
    SETSPECIAL = 4
    GETDYNAMIC = 5
    SETDYNAMIC = 6
    GETINSTANCEVARIABLE = 7
    SETINSTANCEVARIABLE = 8
    GETCLASSVARIABLE = 9
    SETCLASSVARIABLE = 10
    GETCONSTANT = 11
    SETCONSTANT = 12
    GETGLOBAL = 13
    SETGLOBAL = 14
    PUTNIL = 15
    PUTSELF = 16
    PUTOBJECT = 17
    PUTSPECIALOBJECT = 18
    PUTISEQ = 19
    PUTSTRING = 20
    CONCATSTRINGS = 21
    TOSTRING = 22
    TOREGEXP = 23
    NEWARRAY = 24
    DUPARRAY = 25
    EXPANDARRAY = 26
    CONCATARRAY = 27
    SPLATARRAY = 28
    CHECKINCLUDEARRAY = 29
    NEWHASH = 30
    NEWRANGE = 31
    POP = 32
    DUP = 33
    DUPN = 34
    SWAP = 35
    REPUT = 36
    TOPN = 37
    SETN = 38
    ADJUSTSTACK = 39
    DEFINED = 40
    TRACE = 41
    DEFINECLASS = 42
    SEND = 43
    INVOKESUPER = 44
    INVOKEBLOCK = 45
    LEAVE = 46
    FINISH = 47
    THROW = 48
    JUMP = 49
    BRANCHIF = 50
    BRANCHUNLESS = 51
    GETINLINECACHE = 52
    ONCEINLINECACHE = 53
    SETINLINECACHE = 54
    OPT_CASE_DISPATCH = 55
    OPT_CHECKENV = 56
    OPT_PLUS = 57
    OPT_MINUS = 58
    OPT_MULT = 59
    OPT_DIV = 60
    OPT_MOD = 61
    OPT_EQ = 62
    OPT_NEQ = 63
    OPT_LT = 64
    OPT_LE = 65
    OPT_GT = 66
    OPT_GE = 67
    OPT_LTLT = 68
    OPT_AREF = 69
    OPT_ASET = 70
    OPT_LENGTH = 71
    OPT_SIZE = 72
    OPT_SUCC = 73
    OPT_NOT = 74
    OPT_REGEXPMATCH1 = 75
    OPT_REGEXPMATCH2 = 76
    OPT_CALL_C_FUNCTION = 77
    BITBLT = 78
    ANSWER = 79
    VM_INSTRUCTION_SIZE = 80

    RET_NUM = [
               0,
               1,
               0,
               1,
               0,
               1,
               0,
               1,
               0,
               1,
               0,
               1,
               0,
               1,
               0,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               2,
               1,
               1,
               0,
               2,
               1,
               2,
               1,
               1,
               1,
               1,
               1,
               0,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               0,
               0,
               0,
               1,
               1,
               1,
               0,
               0,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               1,
               0,
               1,
               1,
              ]

    def insn_num(insn_name)
      return RubyVM::INSTRUCTION_NAMES.index(insn_name.to_s)
    end

    def insn_ret_num(opcode_index)
      return RET_NUM[opcode_index]
    end

    def insn_stack_increase(opcode_index, opes) 
      depth = 0
      case opcode_index
      when NOP
        return depth + 0
      when GETLOCAL
        return depth + 1
      when SETLOCAL
        return depth + -1
      when GETSPECIAL
        return depth + 1
      when SETSPECIAL
        return depth + -1
      when GETDYNAMIC
        return depth + 1
      when SETDYNAMIC
        return depth + -1
      when GETINSTANCEVARIABLE
        return depth + 1
      when SETINSTANCEVARIABLE
        return depth + -1
      when GETCLASSVARIABLE
        return depth + 1
      when SETCLASSVARIABLE
        return depth + -1
      when GETCONSTANT
        return depth + 0
      when SETCONSTANT
        return depth + -2
      when GETGLOBAL
        return depth + 1
      when SETGLOBAL
        return depth + -1
      when PUTNIL
        return depth + 1
      when PUTSELF
        return depth + 1
      when PUTOBJECT
        return depth + 1
      when PUTSPECIALOBJECT
        return depth + 1
      when PUTISEQ
        return depth + 1
      when PUTSTRING
        return depth + 1
      when CONCATSTRINGS
        inc = 0
        num = opes[0]
        inc += 1 - num
        return depth + inc
      when TOSTRING
        return depth + 0
      when TOREGEXP
        inc = 0
        cnt = opes[1]
        inc += 1 - cnt
        return depth + inc
      when NEWARRAY
        inc = 0
        num = opes[0]
        inc += 1 - num
        return depth + inc
      when DUPARRAY
        return depth + 1
      when EXPANDARRAY
        inc = 0
        num = opes[0]
        flag = opes[1]
        inc += num - 1 + (flag % 2)
        return depth + inc
      when CONCATARRAY
        return depth + -1
      when SPLATARRAY
        return depth + 0
      when CHECKINCLUDEARRAY
        return depth + 0
      when NEWHASH
        inc = 0
        num = opes[0]
        inc += 1 - num
        return depth + inc
      when NEWRANGE
        return depth + -1
      when POP
        return depth + -1
      when DUP
        return depth + 1
      when DUPN
        inc = 0
        n = opes[0]
        inc += n
        return depth + inc
      when SWAP
        return depth + 0
      when REPUT
        inc = 0
        inc += 0
        return depth + inc
      when TOPN
        inc = 0
        inc += 1
        return depth + inc
      when SETN
        inc = 0
        inc += 0
        return depth + inc
      when ADJUSTSTACK
        inc = 0
        n = opes[0]
        inc -= n
        return depth + inc
      when DEFINED
        return depth + 0
      when TRACE
        return depth + 0
      when DEFINECLASS
        return depth + -1
      when SEND
        inc = 0
        op_argc = opes[1]
        op_flag = opes[3]
        inc += - (op_argc + ((op_flag & VM_CALL_ARGS_BLOCKARG) != 0 ? 1 : 0))
        return depth + inc
      when INVOKESUPER
        inc = 0
        op_argc = opes[0]
        op_flag = opes[2]
        inc += - (op_argc + ((op_flag & VM_CALL_ARGS_BLOCKARG) != 0 ? 1 : 0))
        return depth + inc
      when INVOKEBLOCK
        inc = 0
        num = opes[0]
        inc += 1 - num
        return depth + inc
      when LEAVE
        return depth + 0
      when FINISH
        return depth + 0
      when THROW
        return depth + 0
      when JUMP
        return depth + 0
      when BRANCHIF
        return depth + -1
      when BRANCHUNLESS
        return depth + -1
      when GETINLINECACHE
        return depth + 1
      when ONCEINLINECACHE
        return depth + 1
      when SETINLINECACHE
        return depth + 0
      when OPT_CASE_DISPATCH
        inc = 0
        inc += -1
        return depth + inc
      when OPT_CHECKENV
        return depth + 0
      when OPT_PLUS
        return depth + -1
      when OPT_MINUS
        return depth + -1
      when OPT_MULT
        return depth + -1
      when OPT_DIV
        return depth + -1
      when OPT_MOD
        return depth + -1
      when OPT_EQ
        return depth + -1
      when OPT_NEQ
        return depth + -1
      when OPT_LT
        return depth + -1
      when OPT_LE
        return depth + -1
      when OPT_GT
        return depth + -1
      when OPT_GE
        return depth + -1
      when OPT_LTLT
        return depth + -1
      when OPT_AREF
        return depth + -1
      when OPT_ASET
        return depth + -2
      when OPT_LENGTH
        return depth + 0
      when OPT_SIZE
        return depth + 0
      when OPT_SUCC
        return depth + 0
      when OPT_NOT
        return depth + 0
      when OPT_REGEXPMATCH1
        return depth + 0
      when OPT_REGEXPMATCH2
        return depth + -1
      when OPT_CALL_C_FUNCTION
        return depth + 0
      when BITBLT
        return depth + 1
      when ANSWER
        return depth + 1
      end
    end
    module_function :insn_num, :insn_ret_num, :insn_stack_increase
  end
end


