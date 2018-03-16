" This file contains code used only when R run in a Vim buffer

function SendCmdToR_Buffer(...)
    if IsJobRunning(g:rplugin_jobs["R"]) || 1
        if g:R_clear_line
            let cmd = "\001" . "\013" . a:1
        else
            let cmd = a:1
        endif

        " Update the width, if necessary
        if g:R_setwidth
            let rwnwdth = winwidth(g:rplugin_R_winnr)
            if rwnwdth != s:R_width && rwnwdth != -1 && rwnwdth > 10 && rwnwdth < 999
                let s:R_width = rwnwdth
                if has("win32")
                    let cmd = "options(width=" . s:R_width. "); ". cmd
                else
                    call SendToNvimcom("\x08" . $NVIMR_ID . "options(width=" . s:R_width. ")")
                    sleep 10m
                endif
            endif
        endif

        if a:0 == 2 && a:2 == 0
            call term_sendkeys(g:term_bufn, cmd)
        else
            call term_sendkeys(g:term_bufn, cmd . "\n")
        endif
        return 1
    else
        call RWarningMsg("Is R running?")
        return 0
    endif
endfunction

function StartR_InBuffer()
    if string(g:SendCmdToR) != "function('SendCmdToR_fake')"
        return
    endif
    let g:R_tmux_split = 0

    let g:SendCmdToR = function('SendCmdToR_NotYet')

    let edbuf = bufname("%")
    let objbrttl = b:objbrtitle
    let curbufnm = bufname("%")
    set switchbuf=useopen

    if g:R_rconsole_width > 0 && winwidth(0) > (g:R_rconsole_width + g:R_min_editor_width + 1 + (&number * &numberwidth))
        if g:R_rconsole_width > 16 && g:R_rconsole_width < (winwidth(0) - 17)
            silent exe "belowright " . g:R_rconsole_width . "vnew"
        else
            silent belowright vnew
        endif
    else
        if g:R_rconsole_height > 0 && g:R_rconsole_height < (winheight(0) - 1)
            silent exe "belowright " . g:R_rconsole_height . "new"
        else
            silent belowright new
        endif
    endif

    if has("win32")
        call SetRHome()
    endif

    if len(g:rplugin_r_args)
        let rcmd = g:rplugin_R . " " . join(g:rplugin_r_args)
    else
        let rcmd = g:rplugin_R
    endif
    if g:R_close_term
        let g:term_bufn = term_start(rcmd,
                    \ {'exit_cb': function('ROnJobExit'), "curwin": 1, "term_finish": "close"})
    else
        let g:term_bufn = term_start(rcmd,
                    \ {'exit_cb': function('ROnJobExit'), "curwin": 1})
    endif
    let g:rplugin_jobs["R"] = term_getjob(g:term_bufn)

    if has("win32")
        redraw
        call UnsetRHome()
    endif
    let g:rplugin_R_bufname = bufname("%")
    let g:rplugin_R_winnr = winnr()
    let s:R_width = 0
    let b:objbrtitle = objbrttl
    let b:rscript_buffer = curbufnm
    if exists("g:R_hl_term") && g:R_hl_term
        set syntax=rout
        let s:hl_term = g:R_hl_term
    endif
    exe "sbuffer " . edbuf
    call WaitNvimcomStart()
endfunction

if has("win32")
    " The R package colorout only works on Unix systems
    let g:R_hl_term = get(g:, "R_hl_term", 1)
endif
let g:R_setwidth = get(g:, "R_setwidth", 1)
